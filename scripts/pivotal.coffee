# Description:
#   Get current stories from PivotalTracker
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_PIVOTAL_TOKEN
#   HUBOT_PIVOTAL_PROJECT
#
# Commands:
#   show me stories for <project> - shows current stories being worked on
#
# Author:
#   assaf

module.exports = (robot) ->
  robot.respond /show\s+(me\s+)?stories(\s+for\s+)?(.*)/i, (msg)->
    Parser = require("xml2js").Parser
    token = process.env.HUBOT_PIVOTAL_TOKEN


    msg.http("https://www.pivotaltracker.com/services/v3/projects/#{process.env.HUBOT_PIVOTAL_PROJECT}/iterations/current").headers("X-TrackerToken": token).query(filter: "state:unstarted,started,finished,delivered").get() (err, res, body) ->
      if err
        msg.send "Pivotal says: #{err}"
        return

      (new Parser).parseString body, (err, json)->
        for story in json.iteration.stories.story
          message = "##{story.id['#']} #{story.name}"
          message += " (#{story.owned_by})" if story.owned_by
          message += " is #{story.current_state}" if story.current_state && story.current_state != "unstarted"
          msg.send message
      return


  robot.respond /(pivotal story)? (.*)/i, (msg)->
    Parser = require("xml2js").Parser
    token = process.env.HUBOT_PIVOTAL_TOKEN
    project_id = process.env.HUBOT_PIVOTAL_PROJECT
    story_id = msg.match[2]

    msg.http("http://www.pivotaltracker.com/services/v3/projects").headers("X-TrackerToken": token).get() (err, res, body) ->
      if err
        msg.send "Pivotal says: #{err}"
        return
      (new Parser).parseString body, (err, json)->
        for project in json.project
          msg.http("https://www.pivotaltracker.com/services/v3/projects/#{project.id}/stories/#{story_id}").headers("X-TrackerToken": token).get() (err, res, body) ->
            if err
              msg.send "Pivotal says: #{err}"
              return
            if res.statusCode != 500
              (new Parser).parseString body, (err, story)->
                if !story.id
                  return
                message = "##{story.id['#']} #{story.name}"
                message += " (#{story.owned_by})" if story.owned_by
                message += " is #{story.current_state}" if story.current_state && story.current_state != "unstarted"
                msg.send message
                storyReturned = true
                return
    return