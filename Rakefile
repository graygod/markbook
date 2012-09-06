task :default => [:xcode, :install] do
end

task :test do
	tag=`git describe --tag`
    print tag
end

task :info do |t|
	sh 'git log --pretty=oneline | wc -l'
end

task :rev do |t|
    revision = `git log --pretty=oneline | wc -l`
	sh "defaults write `pwd`/markbook/MarkBook.xcodeproj-Info CFBundleVersion %s" % revision
	sh "git add -u"
	sh "git ci --amend"
	sh "make xcode"
end

task :xcode do |t|
	sh "xcodebuild"
	#sh "[ -d /tmp/MarkBook ] || mkdir /tmp/MarkBook"
	sh "rm -rf /tmp/MarkBook/MarkBook.app"
	sh "cp -rf build/Release/MarkBook.app /tmp/MarkBook/MarkBook.app"
end

task :dmg do |t|
	tag = `git describe --tag`
	filename = "MarkBook_%s.dmg" % tag
	sh "ln -sf /Applications /tmp/MarkBook"
	sh "rm -rf ~/Downloads/%s" % filename
	sh "hdiutil create ~/Downloads/%s -srcfolder /tmp/MarkBook" % filename
end

task :install do |t|
	sh "sudo rm -rf /Applications/MarkBook.app"
	sh "sudo cp -rf /tmp/MarkBook/MarkBook.app /Applications"
end

task :zip => :xcode do |t|
	tag = `git describe --tag`.rstrip
	filename= "MarkBook_%s.zip" % tag
    print filename
	sh "zip -r ~/Downloads/%s /tmp/MarkBook/MarkBook.app > /dev/null" % filename
	sh "sign_update.rb ~/Downloads/%s ~/.ssh/dsa_priv.pem" % filename
	sh "ls -l ~/Downloads/%s" % filename
end

task :run => :xcode do |t|
	`build/Release/MarkBook.app/Contents/MacOS/MarkBook`
end
