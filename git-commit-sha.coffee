spawn = __meteor_bootstrap__.require('child_process').spawn
_when = @when

in_git_directory = ->
  result = _when.defer()
  spawn('git', ['rev-parse', '--git-dir'], {stdio: 'ignore'})
  .on 'exit', (code) ->
    result.resolve(code is 0)
  result.promise

index_differences = ->
  result = _when.defer()
  spawn('git', ['diff-index', '--quiet', 'HEAD'], {stdio: 'inherit'})
  .on 'exit', (code) ->
    switch code
      when 0 then result.resolve false
      when 1 then result.resolve true
      else        result.reject  'unable to run git-diff-index'
  result.promise

working_tree_differences = ->
  result = _when.defer()
  spawn('git', ['diff-files', '--quiet'], {stdio: 'inherit'})
  .on('exit', (code) -> result.resolve(code isnt 0))
  result.promise

git_sha = ->
  result = _when.defer()
  process = spawn('git', ['rev-parse', 'HEAD'], {stdio: ['ignore', 'pipe', 2]})
  sha = ''
  process.stdout.on 'data', (data) ->
    sha += data
  process.stdout.on 'end', ->
    sha = sha.trim()
    if sha.length is 40
      result.resolve(sha)
    else
      result.reject('unable to determine HEAD commit sha with git-rev-parse')
  result.promise

fetch_sha = ->
  in_git_directory()
  .then((in_git) ->
    if in_git
      _when.all(
        [ git_sha()
        , index_differences()
        , working_tree_differences()
        ],
        (([sha, index_modified, working_tree_modified]) ->
          sha = sha + ' (modified)' if index_modified or working_tree_modified
          sha
        )
      )
    else
      null
  )

wait_on_promise = (promise) ->
  fiber = Fiber.current
  promise.then(
    ((result) ->
      fiber.run(result)
    ),
    ((reason) ->
      # TODO actually want to throw the error in the fiber, but not sure
      # how to do that.
      console.log reason
      process.exit 1
    )
  )
  Fiber.yield()

sha = wait_on_promise(fetch_sha())

__meteor_runtime_config__.git_commit = sha
