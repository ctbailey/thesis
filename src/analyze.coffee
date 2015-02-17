# analyze harmony / lyric co-occurence

audio_analysis = require('./data/audio_analyses/blue_spotted_tail')
raw_lyrics = require('./data/lyrics/blue_spotted_tail')
pitch_names = require('./data/pitch_names')

class Range
  constructor: (@min, @max) ->

  overlap: (other_range) ->
    @min <= other_range.max &&
    other_range.min <= @max

class WordToken extends Range
  constructor: (@word, timestamp, next_timestamp) ->
    parse_timestamp = (ts) ->
      [minute_string, second_string] = ts.split(":")
      [minutes, seconds] = [parseFloat(minute_string), parseFloat(second_string)]
      total_seconds = seconds + (60.0 * minutes)
      total_seconds
    @word = @word.toLowerCase()
    min = parse_timestamp(timestamp)
    max = parse_timestamp(next_timestamp)
    super min, max

class Segment extends Range
  constructor: (start, duration, @confidence, pitches) ->
    @harmony = new Harmony(pitches)
    super(start, start + duration)

  harmony: ->
    @harmony

class Harmony
  constructor: (@pitches) ->
  triad: ->
    # duplicate array and get three highest values
    highest_strengths = @pitches.slice(0).sort((a, b) -> b - a ).slice(0,3) 
    strongest_pitches = (@pitches.indexOf(strength) for strength in highest_strengths)
    (pitch_names[pitch] for pitch in strongest_pitches)

class Dictionary
  constructor: ->
    @dic = {}
  
  add: (word_token) ->
    @dic[word_token.word] ?= []
    @dic[word_token.word].push(word_token)

  count: (word) ->
    @dic[word].length

# test lyrics

word_tokens = (new WordToken(lyric.word, lyric.timestamp, raw_lyrics[i + 1].timestamp) for lyric, i in raw_lyrics when raw_lyrics[i + 1] isnt undefined)
# console.log word_tokens
d = new Dictionary()
d.add(token) for token in word_tokens
# console.log(JSON.stringify(d, undefined, 2))

# test segments

segments = (new Segment(segment.start, segment.duration, segment.confidence, segment.pitches) for segment in audio_analysis.segments)
# console.log segments

