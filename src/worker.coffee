async = require 'async'

class Worker
  constructor: (options={})->
    { @client, @queuePop, @queuePush } = options
    throw new Error('Worker: requires client') unless @client?
    throw new Error('Worker: requires queuePop') unless @queuePop?
    throw new Error('Worker: requires queuePush') unless @queuePush?
    @shouldStop = false
    @isStopped = false

  doWithNextTick: (callback) =>
    # give some time for garbage collection
    process.nextTick =>
      @do (error) =>
        process.nextTick =>
          callback error

  do: (callback) =>
    @client.time (error, time) =>
      return callback error if error?
      @client.rpoplpush "#{@queuePop}:#{time[0]}", @queuePush, (error) =>
        return callback error

    return # avoid returning promise

  run: (callback) =>
    async.doUntil @doWithNextTick, (=> @shouldStop), =>
      @isStopped = true
      callback null

  stop: (callback) =>
    @shouldStop = true

    timeout = setTimeout =>
      clearInterval interval
      callback new Error 'Stop Timeout Expired'
    , 5000

    interval = setInterval =>
      return unless @isStopped
      clearInterval interval
      clearTimeout timeout
      callback()
    , 250

module.exports = Worker
