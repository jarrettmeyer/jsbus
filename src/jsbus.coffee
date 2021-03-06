# Give CoffeeScript some love. This lets CS get to the root (a.k.a. window) object.
root = exports ? this

# Container object for the event bus.
class EventBus
  constructor: ->
    # Initialize an empty collection of subscribers.
    this.subscribers = { }

  # Create a new event
  createEvent: (eventType, data, callback) ->
    new Event(eventType, data, callback);

  # Publish a new event
  #   eventType: a single event or array of events
  #   data: data related to the event
  #   callback: callback to invoke after the event is published
  publish: (eventType, data, callback) ->
    eventTypes = [].concat(eventType)
    # If data is a function, that really means that no data was given. Do some
    # parameter swapping.
    if isFunction(data)
      callback = data
      data = { }
    createAndPublishEvent(this, eventTypes, data, callback)

  # Reset the event bus. Used in testing. Probably shouldn't be used in production.
  reset: () ->
    this.subscribers = { }

  # Subscribe the given callback to the given event type.
  subscribe: (eventType, callback) ->
    eventTypes = [].concat(eventType)
    subscribeToEventType(this, eventTypes, callback)

  # Unsubscribe all callbacks from the given event type.
  #    eventType: a single event or array of events
  unsubscribe: (eventType) ->
    eventTypes = [].concat(eventType)
    for eventType in eventTypes
      for subscriber in this.subscribers[eventType]
        this.publish("EventBus.unsubscribed", { subscriber: subscriber })
      this.subscribers[eventType] = []

#
class Event
  constructor: (eventType, data, callback) ->
    this.eventType = eventType
    this.data = data ? { }
    this.callback = callback
    this.timestamp = Date.now().toString()

  # Push the event to the given subscriber.
  push: (subscriber) ->
    # Invoke the subscriber's callback function. Save the response. If a callback was given, then invoke the callback.
    response = subscriber.callback(this) ? { }
    if isFunction(this.callback)
      this.callback(response)

#
class Subscriber
  # Create a new subscriber with the given event type and callback.
  constructor: (eventType, callback) ->
    this.eventType = eventType
    this.callback = callback

#
createAndPublishEvent = (eventBus, eventTypes, eventData, callback) ->
  for eventType in eventTypes
    event = eventBus.createEvent(eventType, eventData, callback)
    pushEventToSubscribers(eventBus, event)

# This is the same method UnderscoreJS uses for functional definition.
isFunction = (obj) ->
  !!(obj && obj.constructor && obj.call && obj.apply)

# Push the given event to all subscribers with a matching event type.
pushEventToSubscribers = (eventBus, event) ->
  subscribers = eventBus.subscribers[event.eventType] ? []
  for subscriber in subscribers
    event.push(subscriber)

# Subscribe to the given event types
#   eventBus: event bus instance keeping track of all subscribers
#   eventTypes: array of event types to subscribe
#   callback: function to invoke when the event is published
subscribeToEventType = (eventBus, eventTypes, callback) ->
  for eventType in eventTypes
    subscriber = new Subscriber(eventType, callback)
    eventBus.subscribers[eventType] ?= []
    eventBus.subscribers[eventType].push(subscriber)
    eventBus.publish("EventBus.subscribed", { subscriber: subscriber })

# Create a new EventBus. Prevent eventBus from being defined twice on root.
unless root.eventBus
  root.eventBus = new EventBus()