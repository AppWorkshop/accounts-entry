Meteor.startup ->
  Accounts.urls.resetPassword = (token) ->
    Meteor.absoluteUrl('reset-password/' + token)

  Accounts.urls.enrollAccount = (token) ->
    Meteor.absoluteUrl('enroll-account/' + token)

  AccountsEntry =
    settings: {}

    config: (appConfig) ->
      @settings = _.extend(@settings, appConfig)

  @AccountsEntry = AccountsEntry

  Meteor.methods
    entryValidateSignupCode: (signupCode) ->
      check signupCode, Match.OneOf(String, null, undefined)
      not AccountsEntry.settings.signupCode or signupCode is AccountsEntry.settings.signupCode

    entryCreateUser: (user) ->
      check user, Object
      profile = AccountsEntry.settings.defaultProfile || {}
      if user.username
        userId = Accounts.createUser
          username: user.username,
          email: user.email,
          password: user.password,
          profile: _.extend(profile, user.profile)
      else
        userId = Accounts.createUser
          email: user.email
          password: user.password
          profile: _.extend(profile, user.profile)
      if (user.email && Accounts._options.sendVerificationEmail)
        Accounts.sendVerificationEmail(userId, user.email)

    addOrg : (organization, appName) ->
      check organization, String
      check appName, Match.OneOf(String, null, undefined)

      Meteor.users.update Meteor.userId(),{ $set:{'profile.organization': organization} }
      Meteor.users.update Meteor.userId(),{ $set:{'profile.appName': appName} }

      orgCriteria = {}
      orgNoSpaces = organization.toLowerCase().replace(/ /g, '')

      org = Organization.findOne(orgCriteria)

      if(org && organization)
        throw new Meteor.Error("invalid-organization", "Organization already exists")
      else
        orgId = ''
        unicodeWord = XRegExp("^[\\p{L}\-0-9' ]+$")
        proposed = organization

        if(!unicodeWord.test(proposed))
          throw new Meteor.Error("invalid-organization", "Invalid organization")

        orgId = Organization.insert { name : organization, owner : Meteor.userId(), email : Meteor.user().services.facebook.email}

        Meteor.users.update Meteor.userId(),{ $set:{'profile.organization': orgId} }

        orgIdObj = {}
        orgIdObj[orgId] = ["appAdmin"]
        
        Meteor.users.update Meteor.userId(), {$set:{'roles' : orgIdObj}}

      console.log "working!!!"