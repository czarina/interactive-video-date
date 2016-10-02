## TRACKING LOGIC 
# generate sessionId (based on time in ms + random number)
sessionId = Date.now() + '-' + Utils.randomNumber(0, 1000)

# track buffering events
lastTime = 0.0
lastPlaying = false
window.setInterval( ->
	currPlaying = !videoLayer.player.paused
	currTime = videoLayer.player.currentTime
	#if has been playing for 750ms without any advancement in TS => buffer event
	if lastPlaying and currPlaying and currTime == lastTime
		trackEvent('buffering',
			currVideoTimestamp: currTime,
			currScene: _.last(history)
		)
	lastPlaying = currPlaying
	lastTime = currTime
, 750)

# generic track event function for mixpanel
trackEvent = (event, opts) ->
	opts = opts || {}
	if !_.startsWith(window.location.host, '127.0.0.1')
		mixpanel.track(event, _.extend(opts,
			sessionId: sessionId,
			timestamp: Date.now(),
			videoId: 'dating'
		))

trackEvent 'loaded page'

# track close page events
window.onbeforeunload = () ->
	trackEvent('closed page',
		currVideoTimestamp: videoLayer.player.currentTime,
		currScene: _.last(history)
	)
	undefined
	
# stack of scene indices
history = [0]

# timestamps of scene starts in seconds
sceneStarts = [0, 33.6, 58.4, 100.6, 139.2, 187.6, 220.9, 248]

endScenes = [2, 5, 6]
endScenePauseSegments = [[99, 100.6], [219.5, 220.9], [246.3, 248]]

# timestamp of choice starts in seconds
choiceStarts = [22.1, 48.5, 90.3, 129.6, 175.3, 214.5, 242.2]

# choice coordinate definitions
normalChooseCoords = [[[0.061,0.417],[0.267,0.633]], [[0.72, 0.947],[0.267,0.633]]]
tallChooseCoords = [[[0.057, 0.284], [0.333, 0.587]], [[0.705, 0.947],[0.333, 0.587]]]
goToBeginningChooseCoords = [[[0.076, 0.379], [0.333, 0.6]], [[-1, -1], [-1, -1]]]

# which scene links to which scene 
# [[0's left scene #, 0's right scene #], [1's left scene #, 1's right scene #],....]
sceneLinks = [[1, 3], [2, 4], [0, 0], [5, 6], [5, 6], [0, 0], [0, 0]]

# normalize screen coordinates 
normalizeCoords = (xCoord, yCoord) =>
	print "x, y: ", xCoord, yCoord
	print "mins: ", videoLayer.minX, videoLayer.minY
	print "totals: ", videoLayer.width, videoLayer.height
	xCoordNormalized = (xCoord - videoLayer.minX) / videoLayer.width
	yCoordNormalized = (yCoord - videoLayer.minY) / videoLayer.height
	[xCoordNormalized, yCoordNormalized]
	
# choose button coords for all scenes
chooseCoords = [
	normalChooseCoords,
	tallChooseCoords,
	goToBeginningChooseCoords,
	normalChooseCoords,
	normalChooseCoords,
	goToBeginningChooseCoords,
	goToBeginningChooseCoords
]

# setup a container to hold everything
videoContainer = new Layer
	width: Screen.width
	height: Screen.height
	backgroundColor: 'black'
	shadowBlur: 2
	shadowColor: 'rgba(0,0,0,0.24)'

# create the video layer
videoLayer = new VideoLayer
	x: 0
	y: 0
	width: Screen.width
	height: Screen.height
	video: "images/dating_edited.mp4"
	superLayer: videoContainer

videoLayer.player.setAttribute('preload', 'auto')

# create a thumbnail layer to fill the shared thumbnail
thumbnailLayer = new Layer
	x: 0
	y: 0
	width: Screen.width
	height: Screen.height
	image: "images/thumbnail.png"
	superLayer: videoLayer

# control bar to hold buttons and timeline
controlBar = new Layer
	width:400
	height:100
	backgroundColor:'rgba(0,0,0,0.75)'
	clip:false
	borderRadius:'8px'
	superLayer:videoContainer
	opacity: 1.0
	
# position control bar towards the bottom of the video
controlBar.y = videoContainer.maxY - controlBar.height
controlBar.x = videoContainer.width/2.0 - controlBar.width/2.0

# back-scene layer
backButton = new Layer
	width: 100
	height: 100
	image: 'images/back.png'
	superLayer: controlBar

# play button
playButton = new Layer
	width:100
	height:100
	image:'images/play.png'
	superLayer:controlBar

# position back-scene button to the right of play
playButton.x = backButton.maxX

# home button
homeButton = new Layer
	width: 100
	height: 100
	image: 'images/home.png'
	superLayer: controlBar

# position home button to the right of play
homeButton.x = playButton.maxX	

# skip to choice button
skipToChoiceButton = new Layer
	width: 100
	height: 100
	image: 'images/forward.png'
	superLayer: controlBar

# position skip button to the right of home
skipToChoiceButton.x = homeButton.maxX
# forward-scene layer
forwardScene = new Layer
	x: 0
	y: 0
	width: Screen.width
	height: Screen.height - controlBar.height
	superLayer: videoContainer
	backgroundColor: ""

# Thumbnail in front until an action is taken 
thumbnailLayer.bringToFront()
controlBar.bringToFront()
controlBar.on Events.Click, ->
	thumbnailLayer.opacity = 0.0
	thumbnailLayer.sendToBack()

# helper to initiate play
playHelper = () ->
	trackEvent('play',
		currVideoTimestamp: videoLayer.player.currentTime,
		currScene: _.last(history)
	)
	videoLayer.player.play()
	playButton.image = "images/pause.png"
# helper to initiate pause
pauseHelper = () ->
	trackEvent('pause',
		currVideoTimestamp: videoLayer.player.currentTime,
		currScene: _.last(history)
	)
	videoLayer.player.pause()
	playButton.image = "images/play.png"

# play/pause function
switchPlay = () ->
	thumbnailLayer.opacity = 0.0
	thumbnailLayer.sendToBack()
	if videoLayer.player.paused == true
		playHelper()
	else
		pauseHelper()
	
# Function to handle play/pause button
playButton.on Events.Click, ->
	switchPlay()
	# simple bounce effect on click
	playButton.scale = 1.15
	playButton.animate
		properties:
			scale: 1
		time: 0.1
		curve: 'spring(900,30,0)'
		
# Check whether the device is mobile or not (versus Framer)
if Utils.isMobile()
	# Add event listener on orientation change
	window.addEventListener "orientationchange", -> 
		window.setTimeout( -> 
			updateOrientation(thumbnailLayer.opacity>0.0)
		, 200)
else
	# Listen for orientation changes on the device view
	Framer.Device.on "change:orientation", ->
		window.setTimeout( ->
			updateOrientation(thumbnailLayer.opacity>0.0)
		, 200)

# Resize layers appropriately every time there's an orientation change
updateOrientation = (includeThumbnail) ->
	if Screen.width / Screen.height > (16.0/9.0)
		#print "height limited"
		width = (16.0/9.0) * Screen.height
		height = Screen.height
	else
		#print "width limited"
		width = Screen.width
		height = (9.0/16.0)*Screen.width
	videoContainer.width = Screen.width
	videoContainer.height = Screen.height
	videoLayer.width = width
	videoLayer.height = height
	forwardScene.width = width
	forwardScene.height = height
	videoLayer.center()
	forwardScene.center()
	if controlBar.height + videoLayer.maxY < Screen.height
		controlBar.y = videoLayer.maxY
		controlBar.bringToFront()
	else
		controlBar.y = videoLayer.maxY - controlBar.height
	controlBar.x = videoContainer.width/2.0 - controlBar.width/2.0
	if includeThumbnail
		thumbnailLayer.width = width
		thumbnailLayer.height = height

#set sizing properly on initialization
updateOrientation(true)

# helper function for figuring out if a scene choose button is being pressed
sceneChooseButtonChecker = (xCoord, yCoord, currTime) ->
	
	#print "checking for choice"
	currScene = _.last(history)

	chooseLeft = chooseCoords[currScene][0]
	chooseLeftX = chooseLeft[0]
	chooseLeftY = chooseLeft[1]

	chooseRight = chooseCoords[currScene][1]
	chooseRightX = chooseRight[0]
	chooseRightY = chooseRight[1]
	
	[xCoord, yCoord] = normalizeCoords(xCoord, yCoord)
	pressedButton = false

	# logic for left button choice
	if xCoord >= chooseLeftX[0] and xCoord <= chooseLeftX[1] and yCoord >= chooseLeftY[0] and yCoord <= chooseLeftY[1]
		#print "pressed left"
		currScene = _.last(history)
		nextScene = sceneLinks[currScene][0]
		pressedButton = true
	
	# logic for right button choice
	else if xCoord >= chooseRightX[0] and xCoord <= chooseRightX[1] and yCoord >= chooseRightY[0] and yCoord <= chooseRightY[1]
		#print "pressed right"
		currScene = _.last(history)
		nextScene = sceneLinks[currScene][1]
		pressedButton = true
	
	# if no button was pressed, count as a play/pause event	
	else
		switchPlay()
		
	if pressedButton
		videoLayer.player.currentTime = sceneStarts[nextScene]
		history.push(nextScene)
		videoLayer.player.play()
		playButton.image = "images/pause.png"
		trackEvent('forward scene',
			currVideoTimestamp: currTime,
			currScene: history[history.length - 2],
			nextVideoTimestamp: videoLayer.player.currentTime,
			nextScene: _.last(history)
		)

# Function to handle forward scene choice
# some phones have double tap issues. so dedupe them.
# be careful - (0,0) is invalid
forwardScene.on Events.Tap, (event) ->
	xCoord = event.point.x
	yCoord = event.point.y
	currTime = videoLayer.player.currentTime
	#dedupe taps
	if !(xCoord == 0 and yCoord == 0)
		# if a click occurs while buttons are active during scene, check if a button was clicked
		print "valid tap"
		if true in [Math.round(currTime) in  [Math.round(choiceStarts[x])... Math.round(sceneStarts[x+1])+1] for x in [0...sceneStarts.length-1]][0]
			print "during choice"
			sceneChooseButtonChecker(xCoord, yCoord, currTime)
		# if a click occurs while no buttons are active, play/pause
		else
			switchPlay()
	lastTapTS = currTS
	
# Function to handle back button
backButton.on Events.Click, ->
	startTime = videoLayer.player.currentTime
	startScene = _.last(history)
	history.pop()
	if (history.length == 0)
		history.push(0)
	
	#go to beginning if in first scene before first choice 
	if videoLayer.player.currentTime < choiceStarts[0]
		videoLayer.player.currentTime = 0
	else
		videoLayer.player.currentTime = choiceStarts[_.last(history)]
	trackEvent('back scene',
		currVideoTimestamp: startTime,
		currScene: startScene,
		nextVideoTimestamp: videoLayer.player.currentTime,
		nextScene: _.last(history)
	)
	videoLayer.player.play()

	# simple bounce effect on click
	backButton.scale = 1.15
	backButton.animate
		properties:
			scale:1
		time:0.1
		curve:'spring(900,30,0)'

# Function to handle choose button
skipToChoiceButton.on Events.Click, ->
	currScene = _.last(history)
	nextTime = choiceStarts[currScene]
	trackEvent('skip to choice',
		currVideoTimestamp: videoLayer.player.currentTime,
		currScene: currScene,
		nextVideoTimestamp: nextTime,
		nextScene: currScene
	)
	videoLayer.player.currentTime = nextTime
	videoLayer.player.play()

	# simple bounce effect on click
	skipToChoiceButton.scale = 1.15
	skipToChoiceButton.animate
		properties:
			scale:1
		time:0.1
		curve:'spring(900,30,0)'

# Function to handle home button
homeButton.on Events.Click, ->
	trackEvent('hit home',
		currVideoTimestamp: videoLayer.player.currentTime,
		currScene: _.last(history),
		nextVideoTimestamp: 0,
		nextScene: 0
	)
	videoLayer.player.currentTime = 0
	videoLayer.player.play()
	playButton.image = "images/pause.png"
	
	# simple bounce effect on click
	homeButton.scale = 1.15
	homeButton.animate
		properties:
			scale:1
		time:0.1
		curve:'spring(900,30,0)'
	history = [0]
		
# pause properly at scene ends
window.setInterval( ->
	currTime = videoLayer.player.currentTime
	currScene = _.last(history)
	
	# if at end of movie, pause
	for pauseSegment in endScenePauseSegments
		if currTime > pauseSegment[0] and currTime < pauseSegment[1]
			videoLayer.player.pause()
			playButton.image = "images/play.png"
			trackEvent('reached path end',
				currVideoTimestamp: currTime,
				currScene: currScene
			)
	# if at end of choice, pause
	if currScene not in endScenes and currTime > sceneStarts[currScene + 1] - 4.0
		print "wtf"
		pauseHelper()
, 50)

# white timeline bar
# timeline = new Layer
# 	width:1000
# 	height:50
# 	borderRadius:'10px'
# 	backgroundColor:'#fff'
# 	clip:false
# 	superLayer: videoContainer
# 
# #progress bar to indicate elapsed time
# progress = new Layer
# 	width:0
# 	height:timeline.height
# 	borderRadius:'10px'
# 	backgroundColor:'#03A9F4'
# 	superLayer: timeline
# 
# #scrubber to change current time
# scrubber = new Layer
# 	width:50
# 	height:50
# 	y:-4
# 	borderRadius:'50%'
# 	backgroundColor:'#fff'
# 	shadowBlur:10
# 	shadowColor:'rgba(0,0,0,0.75)'
# 	superLayer: timeline
# 
# #make scrubber draggable
# scrubber.draggable.enabled = true
# 
# # limit dragging along x-axis
# scrubber.draggable.speedY = 0
# 
# # prevent scrubber from dragging outside of timeline
# scrubber.draggable.constraints =
# 	x:0
# 	y:timeline.midY
# 	width:timeline.width
# 	height:-10
# 
# # Disable dragging beyond constraints
# scrubber.draggable.overdrag = false
# 
# # Update the progress bar and scrubber AND CURR/LAST SCENE as video plays
# videoLayer.player.addEventListener "timeupdate", ->
# 	#Calculate progress bar position
# 	newPos = (timeline.width / videoLayer.player.duration) * videoLayer.player.currentTime
# 
# 	#Update progress bar and scrubber
# 	scrubber.x = newPos
# 	progress.width = newPos	+ 10
# 
# # Pause the video at start of drag
# scrubber.on Events.DragStart, ->
# 	videoLayer.player.pause()
# 
# #Update Video Layer to current frame when scrubber is moved
# scrubber.on Events.DragMove, ->
# 	progress.width = scrubber.x + 10
# 
# #When finished dragging set currentTime and play video
# scrubber.on Events.DragEnd, ->
# 	newTime = Utils.round(videoLayer.player.duration * (scrubber.x / timeline.width),0);
# 	videoLayer.player.currentTime = newTime
# 	videoLayer.player.play()
# 	playButton.image = "images/pause.png"
# 
