fs = require 'fs'
path = require 'path'
_ = require 'lodash'
{exec, execSync} = require('child_process')

Kernel = require './kernel'
homePath = process.env[if process.platform == 'win32' then 'USERPROFILE' else 'HOME']

module.exports = KernelManager =
    kernelsDirOptions: [
        path.join(homePath, '.jupyter/kernels'),
        path.join(homePath, 'Library/Jupyter/kernels'),
        '/usr/local/Cellar/python/2.7.9/Frameworks/Python.framework/Versions/2.7/share/jupyter/kernels',
        '/usr/local/share/jupyter/kernels',
        '/usr/share/jupyter/kernels',
        path.join(homePath, '.ipython/kernels')
    ]
    runningKernels: {}
    pythonInfo:
        display_name: "Python"
        language: "python"
    availableKernels: null

    getAvailableKernelspecs: ->
        if @availableKernels?
            return @availableKernels
        else
            kcli="python #{ __dirname }/../scripts/kcli.py"
            kernelspecsJSON = execSync kcli
            kernelspecs = JSON.parse kernelspecsJSON

            for ksError, message of kernelspecs['kernelspecs-errors']
              atom.notifications.addError(message)

            kernelspecs = kernelspecs.kernelspecs
            return kernelspecs

    getTrueLanguage: (language) ->
        languageMappings = @getLanguageMappings()
        matchingLanguageKeys = _.filter languageMappings, (trueLanguage, languageKey) ->
            return languageKey.toLowerCase() == language.toLowerCase()

        if matchingLanguageKeys[0]?
            return matchingLanguageKeys[0].toLowerCase()
        else
            return language

    getLanguageMappings: ->
        try
            languageMappings = JSON.parse atom.config.get('hydrogen.languageMappings')
        catch error
            console.error error
            languageMappings = {}

    getKernelInfoForLanguage: (language) ->
        kernelspecs = @getAvailableKernelspecs()
        console.log "Available kernels:", kernelspecs

        language = @getTrueLanguage(language)

        matchingKernelspecs = _.filter kernelspecs, (kernelspec) ->
          console.log(kernelspec)
          return kernelspec.language? and
                 language.toLowerCase() == kernelspec.language.toLowerCase() 

        matchingKernels = _.filter kernels, (kernel) ->
            kernelLanguage = kernel.language
            kernelLanguage ?= kernel.display_name

            return kernelLanguage? and
                   language.toLowerCase() == kernelLanguage.toLowerCase()

        if matchingKernels.length == 0
            return null
        else
            return matchingKernels[0]

    languageHasKernel: (language) ->
        return @getKernelInfoForLanguage(language)?

    getRunningKernelForLanguage: (language) ->
        language = @getTrueLanguage(language)
        if @runningKernels[language]?
            return @runningKernels[language]
        else
            return null

    languageHasRunningKernel: (language) ->
        return @getRunningKernelForLanguage(language)?

    interruptKernelForLanguage: (language) ->
        kernel = @getRunningKernelForLanguage(language)
        if kernel?
            kernel.interrupt()

    destroyKernelForLanguage: (language) ->
        language = @getTrueLanguage(language)
        if @runningKernels[language]?
            @runningKernels[language].destroy()
            delete @runningKernels[language]

    startKernel: (kernelInfo, config, configFilePath) ->
        language = @getTrueLanguage(kernelInfo.language.toLowerCase())
        kernel = new Kernel(kernelInfo, config, configFilePath)
        @runningKernels[language] = kernel
        return kernel

    execute: (language, code, onResults) ->
        kernel = @getRunningKernelForLanguage(language)
        if kernel?
            kernel.execute(code, onResults)
        else
            throw "No such kernel!"

    complete: (language, code, onResults) ->
        kernel = @getRunningKernelForLanguage(language)
        if kernel?
            kernel.complete(code, onResults)
        else
            throw "No such kernel!"

    destroy: ->
        _.forEach @runningKernels, (kernel) -> kernel.destroy()
