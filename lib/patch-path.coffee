if process.platform == "darwin"

  childProcess = require('child_process')
  shell = process.env.SHELL || '/bin/sh'

  childProcess.exec("launchctl list", launchCtlPathFix)

  launchCtlPathFix = (error, stdout) ->
    if error and error.code != 0
      # Launchctl errored
      console.log("Launchctl errored, not patching path:")
      console.log(stderr)
      console.error(error)
      return

    if stdout
      # process.pid was in the list, make sure that it was a reasonable match
      output = stdout.trim()
      lines = output.split('\n')

      # Verify that at least one of the lines matches the exact pattern of
      # process.pid\t[0\-]\t.*\.Atom
      launchRegex = ///^#{process.pid}\t[0\-]\t.*\.Atom///
      matches = (line for line in lines when launchRegex.exec(line))

      if matches.length > 0
        # Now we think we can fix the path since launcctl was clearly running
        console.error("Atom was launched from Launchctl, attempting to shim PATH")
        childProcess.execFile(shell, ['-c', 'echo $PATH'], patchPath)
      else
        console.log("Your Atom process wasn't in the launchctl list. Using your $PATH as is.")

  patchPath = (error, stdout, stderr) ->
    if (error)
      console.error("Unable to get $PATH")
      console.error("stderr: #{stderr}")
      return

    console.log("Old $PATH: #{process.env.PATH}")
    process.env.PATH = stdout.trim()
    console.log("New $PATH: #{process.env.PATH}")
