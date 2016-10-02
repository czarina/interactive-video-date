getTracker = (videoId) ->
  sessionId = Date.now() + '-' + Utils.randomNumber(0, 1000)

  defaultOpts =
    videoId: videoId
    sessionId: sessionId
    timestamp: Date.now()

  send: (event, opts = {}) ->
    if (!_.startsWith window.location.host, '127.0.0.1')
      mixpanel.track event, _.defaults(opts, defaultOpts)

getSceneManager = (sceneStarts, endScenes, endScenePauseSegments, choiceStarts) ->
  history = [0]

  getHistory: -> history
  getCurrScene: -> _.last(history)
  goBack: ->
    if _.size(history) > 1
      history.pop()
  getSceneStart: (sceneIndex) -> sceneStarts[sceneIndex]

module.exports =
  getTracker: getTracker
