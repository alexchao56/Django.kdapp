class DjangoAppController extends AppController

  KD.registerAppClass this,
    name      : "Django"
    behaviour : "application"
    route     :
      slug    : "/Django"

  constructor : (options = {}, data)->

    options.view    = new DjangoInstaller
    options.appInfo = name : "Django"
    super options, data

class LogWatcher extends FSWatcher

  fileAdded:(change)->
    {name} = change.file
    [percentage, status] = name.split '-'
    @emit "UpdateProgress", percentage, status

domain     = "#{KD.nick()}.kd.io"
OutPath    = "/tmp/_Djangoinstaller.out"
kdbPath    = "~/.koding-Django"
resource   = "https://raw.github.com/alexchao56/Django.kdapp/master"

class DjangoInstaller extends KDView

  constructor:->
    super cssClass: "Django-installer"

  viewAppended:->

    KD.singletons.appManager.require 'Terminal', =>

      @addSubView @header = new KDHeaderView
        title         : "Django Installer"
        type          : "big"

      @addSubView @toggle = new KDToggleButton
        cssClass        : 'toggle-button'
        style           : "clean-gray"
        defaultState    : "Show details"
        states          : [
          title         : "Show details"
          callback      : (cb)=>
            @terminal.setClass 'in'
            @toggle.setClass 'toggle'
            @terminal.webterm.setKeyView()
            cb?()
        ,
          title         : "Hide details"
          callback      : (cb)=>
            @terminal.unsetClass 'in'
            @toggle.unsetClass 'toggle'
            cb?()
        ]

      @addSubView @logo = new KDCustomHTMLView
        tagName       : 'img'
        cssClass      : 'logo'
        attributes    :
          src         : "#{resource}/django.jpg"

      @watcher = new LogWatcher

      @addSubView @progress = new KDProgressBarView
        initial       : 100
        title         : "Checking installation..."

      @addSubView @terminal = new TerminalPane
        cssClass      : 'terminal'

      @addSubView @button = new KDButtonView
        title         : "Install Django"
        cssClass      : 'main-button solid'
        loader        :
          color       : "#FFFFFF"
          diameter    : 24
        callback      : => @installCallback()

      @addSubView @link = new KDCustomHTMLView
        cssClass : 'hidden running-link'
        
      @link.setSession = (session)->
        @updatePartial "Click here to launch Django: <a target='_blank' href='http://#{domain}:3000/Django/#{session}'>http://#{domain}:3000/Django/#{session}</a>"
        @show()

      @addSubView @content = new KDCustomHTMLView
        cssClass : "Django-help"
        partial  : """
          <p>This is an early version of Django, a high-level Python Web framework that encourages rapid 
          development and clean, pragmatic design </p>
          
          <p>Why should you use Django?</p>
          
          <ul>
            <li>
            <strong>Object-relational mapper </strong> Define your own data models entirely in Python. 
            You are given access to a rich, dynamic database-access API for free, but are still able to write SQL if needed. 
            </li>
            <li>
            <strong>Automatic admin interface</strong> Django does all the tedious work of creating interfaes for people to add and update content.
            </li>
            <li>
            <strong>Elegant URL design</strong> Design pretty URLs with no framework-specific limitations. Be as flexible as you like. 
            </li>
            <li>
            <strong>Template System</strong> Django has a powerful and extensible designer-friendly template language to separate design content and python code. 
            </li>
            <li>
            <strong>Cache System</strong> Hook into memocached or other cache frameworks for super performance.
            </li>
            <li>
            <strong>Internationalization</strong> Django has full support for multi-language applications. 
            This lets you specifiy transition strings and provides hooks for language-specific functionality. 
            </li>
            <li>
            <strong>Your Sites Can Grow With You.</strong> You can easily upgrade your site with new features and security. 
            New themes, plugins, and other features can be added without redoing the entire site. 
            </li>

          </ul>
          
          <p>You can see some <a href="http://www.Djangosites.org/">examples </a> of sites that have used Django. Also you can browse
            <a href="https://code.Djangoproject.com/wiki/Tutorials">online tutorials</a> to learn more,
           and stay up to date with news on the <a href="https://www.Djangoproject.com/weblog/">Django blog</a>.</p>
        """

      @checkState()

  checkState:->

    vmc = KD.getSingleton 'vmController'

    @button.showLoader()

    FSHelper.exists "~/.koding-Django/Django.js", vmc.defaultVmName, (err, Django)=>
      warn err if err
      
      unless Django
        @link.hide()
        @progress.updateBar 100, '%', "Django is not installed."
        @switchState 'install'
      else
        @progress.updateBar 100, '%', "Checking for running instances..."
        @isBracketsRunning (session)=>
          if session
            message = "Django is running."
            @link.setSession session
            @switchState 'stop'
          else
            message = "Django is not running."
            @link.hide()
            @switchState 'run'
            if @_lastRequest is 'run'
              delete @_lastRequest

              modal = KDModalView.confirm
                title       : 'Failed to run Django'
                description : 'It might not have been installed to your VM or not configured properly.<br/>Do you want to re-install Django?'
                ok          :
                  title     : 'Re-Install'
                  style     : 'modal-clean-green'
                  callback  : =>
                    modal.destroy()
                    @switchState 'install'
                    @installCallback()
                    @button.showLoader()

          @progress.updateBar 100, '%', message
  
  switchState:(state = 'run')->

    @watcher.off 'UpdateProgress'

    switch state
      when 'run'
        title = "Run Django"
        style = 'green'
        @button.setCallback => @runCallback()
      when 'install'
        title = "Install Django"
        style = ''
        @button.setCallback => @installCallback()
      when 'stop'
        title = "Stop Django"
        style = 'red'
        @button.setCallback => @stopCallback()

    @button.unsetClass 'red green'
    @button.setClass style
    @button.setTitle title or "Run Django"
    @button.hideLoader()

  stopCallback:->
    @_lastRequest = 'stop'
    @terminal.runCommand "pkill -f '.koding-Django/Django.js' -u #{KD.nick()}"
    KD.utils.wait 3000, => @checkState()

  runCallback:->
    @_lastRequest = 'run'
    session = (Math.random() + 1).toString(36).substring 7
    @terminal.runCommand "node #{kdbPath}/Django.js #{session} &"
    KD.utils.wait 3000, => @checkState()

  installCallback:->
    @watcher.on 'UpdateProgress', (percentage, status)=>
      @progress.updateBar percentage, '%', status
      if percentage is "100"
        @button.hideLoader()
        @toggle.setState 'Show details'
        @terminal.unsetClass 'in'
        @toggle.unsetClass 'toggle'
        @switchState 'run'
      else if percentage is "0"
        @toggle.setState 'Hide details'
        @terminal.setClass 'in'
        @toggle.setClass 'toggle'
        @terminal.webterm.setKeyView()

    session = (Math.random() + 1).toString(36).substring 7
    tmpOutPath = "#{OutPath}/#{session}"
    vmc = KD.getSingleton 'vmController'
    vmc.run "rm -rf #{OutPath}; mkdir -p #{tmpOutPath}", =>
      @watcher.stopWatching()
      @watcher.path = tmpOutPath
      @watcher.watch()
      @terminal.runCommand "curl --silent #{resource}/installer.sh | bash -s #{session}"

  isBracketsRunning:(callback)->
    vmc = KD.getSingleton 'vmController'
    vmc.run "pgrep -f '.koding-Django/Django.js' -l -u #{KD.nick()}", (err, res)->
      if err then callback false
      else callback res.split(' ').last

# Helper for testing in Kodepad
appView.addSubView new DjangoInstaller
cssClass: ".Django-installer"