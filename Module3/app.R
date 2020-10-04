library(shiny)
library(dplyr)
library(rsconnect)
library(ggplot2)
library(ggthemes)

df <- read.csv('https://raw.githubusercontent.com/charleyferrari/CUNY_DATA_608/master/module3/data/cleaned-cdc-mortality-1999-2010-2.csv')

filtered_df <- df %>% 
  filter(Year == '2010')

ui <- fluidPage(titlePanel(title='An Examination of Mortality Rates and Causes Across the United States'),
                hr(),
                h5(strong('Question #1:'), 'As a researcher, you frequently compare mortality rates from particular
                   causes across different States. You need a visualization that will let you see (for
                   2010 only) the crude mortality rate, across all States, from one cause (for example,
                   Neoplasms, which are effectively cancers). Create a visualization that allows you
                   to rank States by crude mortality for each cause of death.'),
                hr(),
                sidebarPanel(
                  selectInput('Cause', 'Cause of Death', sort(unique(filtered_df$ICD.Chapter)),
                             selected='Certain conditions originating in the perinatal period')
                ),
              mainPanel(
                htmlOutput(outputId = 'selection'),
                plotOutput('q1plot', width="80%", height="550px"),
                htmlOutput(outputId = 'explainer'),
                br()
              ),
              hr(),
              h5(strong('Question #2:'), 'Often you are asked whether particular States are improving their
                 mortality rates (per cause) faster than, or slower than, the national average. Create a
                 visualization that lets your clients see this for themselves for one cause of death at the
                 time. Keep in mind that the national average should be weighted by the national population.'
                 ),
              hr(),
              sidebarPanel(
                selectInput('Cause2', 'Cause of Death', sort(unique(df$ICD.Chapter)),
                            selected='Certain conditions originating in the perinatal period')
              ),
              sidebarPanel(
                selectInput('State', 'State', sort(unique(df$State)), selected = 'AL')
              ),
              mainPanel(
                htmlOutput(outputId = 'selection2'),
                span(textOutput("legend1"), style="color:steelblue; font-weight:600"),
                span(textOutput("legend2"), style="color:#ceb59f; font-weight:600"),
                plotOutput('q2plot', width = "80%", height = "450px")
              )

        )

server <- function(input, output){
  
  # Part 1

  output$selection <- renderText({
    paste('<strong>Crude mortality rate for: ', input$Cause, ' (2010 only) </strong>')
  })

  output$explainer <- renderText({
    paste('<small>*Crude Mortality Rate is calculated by dividing the number of deaths for a particular cause by the state population and multiplying by 100,000.</small>')
  })


  selectedData <- reactive({
    filtered_df %>% filter(ICD.Chapter == input$Cause)
  })

  selectedMax <- reactive({
    val <- filtered_df %>%
      filter(ICD.Chapter == input$Cause) %>%
      slice(which.max(Crude.Rate))

    val['Crude.Rate'][,1]
  })


  output$q1plot <- renderPlot({

    p <- ggplot(selectedData(), aes(x=reorder(State, Crude.Rate), y=Crude.Rate)) +
      geom_bar(stat = "identity", fill = "steelblue") + coord_flip()

    plot <- ggplot_build(p)
    x.ticks <- plot$layout$panel_params[[1]]$x$minor_breaks

    p <- p + geom_hline(yintercept=x.ticks, col="white", lwd=1)

    p <- p + scale_y_continuous(expand = c(0, 0), limits = c(0, selectedMax() + selectedMax() * 0.15))
    p <- p + theme(plot.title = element_text(size=12, face="bold", hjust = 0.25),
               axis.text=element_text(size=9, face = "bold"),
               axis.title=element_text(size=9,face="bold", color = "#555555"),
               panel.background = element_blank(),
               axis.line = element_line(color = "#cccccc",
                                        size = 0.5, linetype = "solid"),
               axis.ticks.y = element_blank(),
               axis.ticks.x = element_line(color="#cccccc"))
    p <- p + geom_text(aes(label = Crude.Rate, size = 1), vjust = 0.20, hjust = -0.25, size=2.5, fontface='bold', color="steelblue")

    p + ylab("Crude Rate (2010)") + xlab("State")
  })
  
  # Part 2
  deaths_per_year <- df %>%
    group_by(ICD.Chapter, Year) %>%
    summarise(Deaths_Year = sum(Deaths))
  
  
  population_per_year <- df %>%
    filter(ICD.Chapter == 'Neoplasms') %>%
    group_by(Year) %>%
    summarise(Year_Population = sum(Population))
  
  for (i in 1:length(df$ICD.Chapter)){
    for (j in 1:length(population_per_year$Year)) {
      if (df$Year[i] == population_per_year$Year[j]){
        df$US_Population[i] = population_per_year$Year_Population[j]
      }
    }
  }
  
  
  library(plyr)
  
  df2 <- join(df, deaths_per_year)
  
  detach("package:plyr", unload = TRUE)
  
  df2$National_Crude_Rate <- (df2$Deaths_Year / df2$US_Population) * 100000
  
  output$selection2 <- renderText({
    paste('<strong> [', input$State, '] trend in crude mortality rate over time for: ', input$Cause2, '</strong>')
  })
  
  output$legend1 <- renderText({"State Mortality Rate"})
  output$legend2 <- renderText({"National Average Mortality Rate"})
  
  output$q2plot <- renderPlot({

      data <- subset(df2, ICD.Chapter == input$Cause2 & State == input$State)
      
      p <- ggplot(data, aes(x=Year)) +
        geom_area(aes(y = Crude.Rate), fill = "steelblue", color = "steelblue", alpha = 0.7, size = 2) + 
        geom_area(aes(y = National_Crude_Rate), fill = "#ceb59f", color = "#ceb59f", size = 2, alpha = 0.5) + 
        ylim(0, max(data$Crude.Rate, data$National_Crude_Rate) * 1.25) +
        xlab("Year") +
        ylab("Crude Mortality Rate per 100,000 people")
      
      p <- p + theme(
        axis.text=element_text(size=9, face = "bold"),
        axis.title=element_text(size=9,face="bold", color = "#555555"),
        panel.background = element_blank(),
        axis.line = element_line(color = "#cccccc",
                                 size = 0.5, linetype = "solid"),
        axis.ticks.y = element_blank(),
        axis.ticks.x = element_line(color="#cccccc")
        )
  
      p

  })
} 

shinyApp(ui = ui, server = server)