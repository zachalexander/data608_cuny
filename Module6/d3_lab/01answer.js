d3.csv('ue_industry.csv', data => {

    // Define your scales and generator here.

    const xScale = d3.scaleLinear()
        .domain(d3.extent(data, d => +d.index))
        .range([20, 1180]);

    const yScale = d3.scaleLinear()
        .domain(d3.extent(data, d => +d.Agriculture))
        .range([580, 20]);

    let line_ans = d3.line()
        .x(d => xScale(d.index))
        .y(d => yScale(d.Agriculture))

    d3.select('#answer1')
        // append more elements here
        .append('path')
        .attr('stroke', 'black')
        .attr('stroke-width', '1px')
        .attr('d', line_ans(data))


});
