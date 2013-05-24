@tageswoche = @tageswoche || {}

tageswoche.scorecard = do ->

  statistics: {}
  filter: {}
  data: {}


  init: (player) ->
    @player = player.replace("_", ". ")
    @loadStatistics(@filter, $.proxy(@redrawCard, @))


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
        @statistics[filterString] = data
        callback(data)
      return


  redrawCard: (data) ->
    for value in data.list
      if value.nickname == @player
        $('#player-name').html(value.name)
        $('#minutes-played span').html(value.minutes)
        $('#games-played span').html(value.played)
        $('#goals span').html(value.goals)
        $('#assists span').html(value.assists)
        $('#yellow-cards span').html(value.yellowCards)
        $('#yellow-red-cards span').html(value.yellowRedCards)
        $('#red-cards span').html(value.redCards)
        tageswoche.formcurve.draw(value.grades)
        return