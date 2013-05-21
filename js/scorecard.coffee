@tageswoche = @tageswoche || {}

tageswoche.scorecard = do ->

  # curve chart margins
  margin = {top: 5, right: 5, bottom: 50, left: 20}
  width = 1280 - margin.left - margin.right
  height = 200 - margin.top - margin.bottom

  x = d3.time.scale().range([0, width])
  y = d3.scale.linear().range([height, 0]).nice()
  color = d3.scale.linear().range(["red", "yellow", "green"])

  statistics: {}
  filter: {}
  data: {}

  init: () ->
    @loadStatistics(@filter, $.proxy(@redrawCard, @))


  # NOTE: when loaded on same page as player table, don't use
  loadStatistics: (filter, callback) ->
    filterString = ""
    if filter.location then filterString += "location=#{filter.location}&"
    if filter.competition then filterString += "competition=#{filter.competition}"
    #if filter.game then filterString += "game=#{filter.game}"
    if filterString == "" then filterString = "all"
    # console.log("Filter is #{filterString}")

    if @statistics[filterString]
      callback(@statistics[filterString])
      return
    else
      $.ajax(
        url: "http://tageswoche.herokuapp.com/fcb/statistics?#{filterString}",
        dataType: "jsonp"
      ).done ( data ) =>
        @statistics[filterString] = data
        callback(data)
      return


  redrawCard: (data) ->
    # TODO still hard-coded
    @drawBarchart(data.list[16].grades)
    console.log "drawing..."


  drawBarchart: (data) =>
    playerData = []
    for index, player of data
      playerData.push
        date: new Date(player.date)
        grade: +player.grade

    console.log "in draw function:"
    console.log playerData
    console.log typeof playerData
    svg_container = d3.select(".curve").append("svg")
      .attr('class', 'barchart')
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)

    svg = svg_container.append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

    x.domain(d3.extent(playerData, (d, i) ->
      d.date
    ))
    y.domain([d3.min(playerData, (d) ->
      if d.grade == 0
        5
      else
        d.grade
    ), 6])
    color.domain([2,4,6])

    xAxis = d3.svg.axis().scale(x).orient("bottom")
    yAxis = d3.svg.axis().scale(y).orient('left').ticks(6)

    svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(0,' + height + ')')
      .call(xAxis)
      # .selectAll('text')
      #   .style('text-anchor', 'end')
      #   .attr('dx', '-.8em')
      #   .attr('dy', '.15em')
      #   .attr('transform', (d) ->
      #     "rotate(-65)"
      #   )

    svg.append('g')
      .attr('class', 'y axis')
      .call(yAxis)

    svg.selectAll('circle')
      .data(playerData)
      .enter()
      .append('circle')
        .attr('cx', (d) ->
          console.log "x-value: #{d.date}"
          console.log "drawing: #{x(d.date)}"
          x(d.date)
        )
        .attr('cy', (d) ->
          console.log "y-value: #{d.grade}"
          console.log "drawing: #{y(d.grade)}"
          y(d.grade)
        )
        .attr('class', (d) ->
          'invisible' if d.grade == 0
        )
        .attr('fill', (d) ->
          color(d.grade)
        )
        .attr('r', 4)
      .exit().remove()
