cloneBuffer = (inputBuffer) ->
  outputBuffer = new Float32Array(inputBuffer.length)

  for i in [0...inputBuffer.length] by 1
    outputBuffer[i] = inputBuffer[i]

  outputBuffer

copyBuffer = (inputBuffer, outputBuffer, outputOffset) ->
  for i in [0...inputBuffer.length] by 1
    outputBuffer[i + outputOffset] = inputBuffer[i]

  inputBuffer.length

class Track

  constructor: (@options) ->
    @context = @options.context
    @stream = @options.stream
    @samples = []

  record: ->
    console.log 'recording...'

    source = @context.createMediaStreamSource(@stream)
    @capture = @context.createScriptProcessor(512, 2, 2)

    @capture.onaudioprocess = (event) =>
      if !@recording then return

      @samples.push [
        cloneBuffer event.inputBuffer.getChannelData(0)
        cloneBuffer event.inputBuffer.getChannelData(1)
      ]

    source.connect @capture
    @capture.connect @context.destination

    @recording = true

  stop: ->
    console.log 'stopping...'

    if @recording
      @capture.disconnect()
      @recording = false

    if @playing
      @source.disconnect()
      @playing = false

  play: ->
    console.log 'playing...'

    @source = @context.createBufferSource()
    output = @context.createBuffer(2, @samples.length * 512, @context.sampleRate)
    outputL = output.getChannelData(0)
    outputR = output.getChannelData(1)
    offsetL = 0
    offsetR = 0

    for buffer in @samples
      offsetL += copyBuffer(buffer[0], outputL, offsetL)
      offsetR += copyBuffer(buffer[1], outputR, offsetR)

    @source.buffer = output
    @source.connect @context.destination
    @source.start 0

    @playing = true

requirejs.config
  paths:
    jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'

require ['jquery'], ($) ->
  navigator.webkitGetUserMedia audio: true, (stream) ->

    tracks = $('.track').map (i, $track) ->
      track = new Track
        stream: stream
        context: new window.webkitAudioContext()

      $('.record', $track).click -> track.record()
      $('.stop', $track).click -> track.stop()
      $('.play', $track).click -> track.play()

      track

    $('.playall').click ->
      tracks.each (i, track) -> track.play()
