echojs = require('echojs')
en = echojs(
  key: 'FED71CAENZYD7HJTB' 
)
ff_uris = require('./ff_spotify_uris')
rem = require('rem')
client = rem.createClient({ format: 'json' })
fs = require('fs')
sanitize = require('sanitize-filename')

report_error = (song, err, json) ->
  console.log "Found error (code #{err}) when processing #{song.title}. #{JSON.stringify(json, undefined, 2)}" 

# retrieve all fleet foxes songs

current_start = 0
songs = []

log_songs = (err, json) ->
  console.log json.response
  current_start = json.response.start + json.response.songs.length
  songs = songs.concat json.response.songs
  if songs.length < json.response.total 
    get_songs() 
  else
    console.log(JSON.stringify(songs, undefined, 2))

get_songs = ->
  en('artist/songs').get
    name: 'fleet+foxes'
    start: current_start
  , log_songs

# get_songs()

# make sure Spotify URIs match song titles

checked_songs = 0
results = {}

check_uri_of = (song) ->
  en('track/profile').get
    id: song.id
  , (err, json) ->
    if err == 0
      results[song.title] = json.response.track.title
      checked_songs++
      report_results() if checked_songs == ff_uris.length
    else
      report_error song, err, json

report_results = ->
  mismatches = ("Local title: #{local_title}, EchoNest title: #{en_title}" for local_title, en_title of results when local_title isnt en_title)
  if mismatches.length == 0
    console.log 'All songs match'
  else
    console.log "Found some mismatches:\n#{mismatches.join('\n')}"

check_ff_uris = -> (check_uri_of song for song in ff_uris)

# check_ff_uris()

# get audio analyses for songs

get_audio_analysis_of = (song) ->
  get_analysis_url song, save_full_analysis

get_analysis_url = (song, callback) ->
  en('track/profile').get
    id: song.id
    bucket: 'audio_summary'
  , (err, json) ->
    if err == 0
      callback(song, json.response.track.audio_summary.analysis_url)
    else 
      report_error song, err, json

save_full_analysis = (song, analysis_url) ->
  console.log "Retrieving full analysis for #{song.title}"
  callback = (err, content, response) ->
    if err == 0
      console.log "Saving data for #{song.title}"
      pretty_output = JSON.stringify(content, undefined, 2)
      path = "./full_analyses/#{sanitize(song.title)}.js"
      require('fs').writeFile(path, pretty_output, (err) -> report_error(song, err) if err?)
    else
      report_error song, err, content
      
  client(analysis_url).get({}, callback)

get_audio_analyses = -> (get_audio_analysis_of song for song in ff_uris)

# get_audio_analyses()
