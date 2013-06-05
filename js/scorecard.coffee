@tageswoche = @tageswoche || {}

tageswoche.scorecard = do ->

  statistics: {}
  filter: {}
  data: {}


  init: (player) ->
    @player = player.replace("_", ". ")
    @loadStatistics(@filter, $.proxy(@redrawCard, @))
    # events
    $("#competition-filter").on "change", (event) =>
      # console.log "filter changed"
      $this = $(event.currentTarget)
      @filter ?= {}
      @filter.competition = $this.val()
      @loadStatistics(@filter, $.proxy(@redrawCard, @))


  getPlayerFromUrl: () ->
    @getUrlParameter("spieler")


  getUrlParameter: (name) ->
    value = RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)?[1]
    decodeURI(value) if value


  # NOTE: when loaded on same page as player table, don't use
  loadStatistics: (filter, callback) ->
    filterString = ""
    if filter.location then filterString += "location=#{filter.location}&"
    if filter.competition then filterString += "competition=#{filter.competition}"
    if filterString == "" then filterString = "all"

    if @statistics[filterString]
      callback(@statistics[filterString])
      return
    else
      $.ajax(
        url: "http://tageswoche.herokuapp.com/fcb/statistics?#{filterString}",
        dataType: "jsonp"
      ).done ( data ) =>
        # console.log data
        @statistics[filterString] = data
        callback(data)
      return


  redrawCard: (data) ->
    for value in data.list
      # console.log value
      if value.nickname == @player
        $('#player-name').html(value.name)
        $('#minutes-played span').html(value.minutes)
        $('#games-played span').html(value.played)
        $('#goals span').html(value.goals)
        $('#assists span').html(value.assists)
        $('#yellow-cards span').html(value.yellowCards)
        $('#yellow-red-cards span').html(value.yellowRedCards)
        $('#red-cards span').html(value.redCards)
        $('#average-grade span').html(Math.floor(value.averageGrade*10)/10)
        tageswoche.formcurve.draw(value.grades)
        return
