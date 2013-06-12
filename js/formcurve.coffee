@tageswoche = @tageswoche || {}

tageswoche.formcurve = do ->

  initialized = false
  brush = undefined

  containerWidth = $('.curve').width()

  # focus chart margins
  margin =
    top: 105
    right: 5
    bottom: 20
    left: 25
  width = containerWidth - margin.left - margin.right
  height = 380 - margin.top - margin.bottom

  # context chart margins
  marginContext =
    top: 10
    bottom: 325
    right: 5
    left: 90

  heightContext = 380 - marginContext.top - marginContext.bottom
  widthContext = containerWidth - marginContext.left - marginContext.right

  # scales
  x = d3.time.scale().range([0, width])
  xContext = d3.time.scale().range([0, widthContext])
  y = d3.scale.linear().range([height, 0])
  yContext = d3.scale.linear().range([heightContext, 0])
  color = d3.scale.linear().range(['#D7191C', '#D7191C', '#FDAE61', '#FFFFBF', '#A6D96A', '#1A9641'])

  # axes
  xAxisContext = d3.svg.axis().scale(xContext).orient('bottom').ticks(6)
  yAxis = d3.svg.axis().scale(y).orient('left').ticks(6)
  xAxis = d3.svg.axis().scale(x).orient('bottom')

  # svg containers
  svg_container = d3.select('.curve').append('svg')
    .attr('class', 'curve-svg')
    .attr('width', width + margin.left + margin.right)
    .attr('height', height + margin.top + margin.bottom)

  focus = svg_container.append("g")
    .attr('transform', "translate(#{margin.left},#{margin.top})")
    .attr('class', 'focus-svg')

  tooltip = d3.select('.curve').append('div')
    .attr('class', 'tooltip')
    .style('opacity', 0)

  context = svg_container.append('g')
    .attr('transform', "translate(#{marginContext.left},#{marginContext.top})")

  legend = svg_container.append('g')
    .attr('class', 'legend')

  legend.append('path')
    .attr('d', "M 5 25 L 5 30 L 70 30 L 70 35 L 80 27.5 L 70 20 L 70 25 L 5 25")
    .attr('fill', '#777')
    .attr('fill-opacity', .7)
  legend.append('text')
      .text('Zeitauswahl')
      .attr('transform', 'translate(5, 15)')

  # legend.append('path')
  #   .attr('d', "M 5 5 L 10 5 L 10 60 L 15 60 L 7.5 70 L 0 60 L 5 60 L 5 5")
  #   .attr('fill', '#777')
  #   .attr('fill-opacity', .7)

  legend.append('text')
    .text('Spielerbewertung')
    .attr('transform', 'translate(0, 80)')


  sanitizeData: (data) ->
    sanitizedData = []
    for index, player of data
      grade = +player.grade
      if grade == 0
        grade = null
      #grade = null if grade == 0
      if player.date
        sanitizedData.push
          date: new Date(player.date)
          grade: grade
          averageGrade: +player.gameAverageGrade
          opponent: player.opponent
    sanitizedData


  setupDomains: (sanitizedData) ->
    # x.domain([d3.max(sanitizedData, (d) ->
    #   d.date
    # ), d3.min(sanitizedData, (d) ->
    #   d.date
    # )])
    x.domain(d3.extent(sanitizedData.map( (d) ->
      d.date
    )))
    y.domain([0.8, 6.2]) # a little above 6 should be visible for radii
    color.domain([1,2,3,4,5,6])


  redrawFocusChart: () ->
    circles = focus.selectAll('circle')
      .attr('cx', (d) ->
        x(d.date)
      )
      .attr('cy', (d) ->
        y(d.grade)
      )
      .attr('class', (d) ->
        'invisible' if d.grade == 0
      )
      .attr('fill', (d) ->
        color(d.grade)
      )
      .attr('r', @getRadius())
      .attr('clip-path', 'url(#clip)')
      .on('mouseover', @circleMouseover)
      .on('mouseout', @circleMouseout)
    circles


  draw: (data) ->
    sanitizedData = @sanitizeData(data)

    # clip path
    svg_container.append('defs').append('clipPath')
      .attr('id', 'clip')
      .append('rect')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)

    @setupDomains(sanitizedData)

    # focus chart
    focus.append('g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(0,' + height + ')')
      .call(xAxis)

    focus.append('g')
      .attr('class', 'y axis')
      .call(yAxis)

    circles = focus.selectAll('circle')
      .data(sanitizedData)

    circles.enter()
      .append('circle')
        .attr('cx', (d) ->
          x(d.date)
        )
        .attr('cy', (d) ->
          y(d.grade)
        )
        .attr('class', (d) ->
          'invisible' if d.grade == 0
        )
        .attr('fill', (d) ->
          color(d.grade)
        )
        .attr('r', @getRadius())
        .attr('clip-path', 'url(#clip)')
        .on('mouseover', @circleMouseover)
        .on('mouseout', @circleMouseout)

    circles.exit()
      .remove()

    # context chart
    xContext.domain(x.domain())
    yContext.domain(y.domain())

    context.append('g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(0,' + heightContext + ')')
      .call(xAxisContext)

    contextBars = context.selectAll('rect')
      .data(sanitizedData)

    contextBars.enter()
      .append('rect')
        .attr('x', (d) ->
          xContext(d.date)
        )
        .attr('y', (d) ->
          yContext(d.grade)
        )
        .attr('height', (d) ->
          h = heightContext - yContext(d.grade)
          if h > 0
            h
          else
            0
        )
        .attr('fill', (d) ->
          color(d.grade)
        )
        .attr('width', 2)

    contextBars.exit()
      .remove()

    # brush
    brushCallback = $.proxy(@contextBrush, @)
    brush = d3.svg.brush()
      .x(xContext)
      .on('brush', brushCallback)

    # sets the brush by default to: from now - 60 days ago
    today = new Date()
    twoMonthsAgo = new Date()
    twoMonthsAgo.setDate( (twoMonthsAgo.getDate() - 60) )
    brush.extent([twoMonthsAgo, today])
    # brush.extent([sanitizedData[sanitizedData.length - 15].date,
    #             sanitizedData[sanitizedData.length - 1].date])

    context.append('g')
      .attr('class', 'x brush')
      .call(brush)
      .selectAll('rect')
        .attr('y', -6)
        .attr('height', heightContext + 7)

    context.select('.brush').call(brushCallback)
    initialized = true

  getRadius: () ->
    millisecondsPerDay = 1000 * 60 * 60 * 24
    if brush
      dayDiff = (brush.extent()[1].getTime() - brush.extent()[0].getTime()) / millisecondsPerDay
      size = 600 / dayDiff
      if size > 8
        8
      else
        size
    else
      5


  contextBrush: () ->
    selection = brush.extent()
    if brush.empty()
      x.domain(xContext.domain())
    else
      x.domain(selection)

    focus.select(".x.axis").call(xAxis)
    @redrawFocusChart()


  circleMouseover: (d) ->
    d3.select(this)
      .transition().duration(100)
      .attr('r', 20)
      .transition().duration(100)
      .attr('r', 15)


    if d.grade > d.averageGrade
      # only draw an arrow line if its longer than the radius
      if y(d.averageGrade) - y(d.grade) > 15
        path = "M  #{x(d.date)} #{y(d.averageGrade)} L #{x(d.date)} #{y(d.grade) + 15} L #{x(d.date) + 5} #{y(d.grade) + 23} L #{x(d.date) - 5} #{y(d.grade) + 23} L #{x(d.date)} #{y(d.grade) + 15}"
        d3.select('.focus-svg')
          .append('path')
            .attr('d', path)
            .attr('stroke', 'green')
      text = """
        Note: #{d.grade} &ndash;<br/>
        Gegner: #{d.opponent} &ndash;<br/>
        <b>+#{Math.floor((d.grade - d.averageGrade)*10) / 10}</b> gegenüber Team-Schnitt
        """
      tooltipY = 60
    else
      if y(d.grade) - y(d.averageGrade) > 15
        path = "M #{x(d.date)} #{y(d.averageGrade)} L #{x(d.date)} #{y(d.grade) - 15} L #{x(d.date) + 5} #{y(d.grade) - 23} L #{x(d.date) - 5} #{y(d.grade) - 23} L #{x(d.date)} #{y(d.grade) - 15}"
        focus.append('path')
          .attr('d', path)
          .attr('stroke', 'red')
      text =
        """
        Note: #{d.grade} &ndash;<br/>
        Gegner: #{d.opponent} &ndash;<br/>
        <b>-#{Math.floor((d.averageGrade - d.grade)*10) / 10}</b> gegenüber Team-Schnitt
        """
      tooltipY = -30
    # set tooltip
    tooltip.transition().duration(200)
      .style('opacity', .9)
    tooltip.html(text)
      .style('left', "#{x(d.date) + margin.left + 15}px")
      .style('top', "#{y(d.grade) + margin.top + tooltipY}px")
      # .style('left', "#{x(d.date) + margin.left + 15}px")
      # .style('top', "#{y(d.grade) + height + tooltipY}px")


  circleMouseout: (d) ->
    d3.select(this)
      .transition().duration(100)
      .attr('r', tageswoche.formcurve.getRadius())

    focus.selectAll('path').remove()
    tooltip.transition().duration(200)
      .style('opacity', 0)
