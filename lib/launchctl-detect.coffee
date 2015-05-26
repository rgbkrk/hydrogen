if process.platform == "darwin"

  childProcess = require('child_process')
  shell = process.env.SHELL || '/bin/sh'

  patchPath = (error, stdout, stderr) ->
    if (error)
      console.error("Unable to get $PATH")
      console.error("stderr: #{stderr}")
      return
    process.env.PATH = stdout.trim()

  parseLaunchCtl = (error, stdout, stderr) ->
    if error and error.code != 0
      # Could not find the Atom process within the launchctl list
      # Likely launched using the terminal. Do nothing
      console.log("Using your $PATH rather than trying to guess, based on launchctl error:")
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
        console.error("Atom was launched from Launchctl, faking PATH")
        childProcess.execFile(shell, ['-c', 'echo $PATH'], patchPath)

    if stderr
      console.log("stderr from launchctl: #{stderr}")

  childProcess.exec("launchctl list", parseLaunchCtl)
