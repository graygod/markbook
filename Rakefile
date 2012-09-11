
task :default => [:xcode, :install] do
end

task :info do |t|
	sh 'git log --pretty=oneline | wc -l'
end

task :rev do |t|
    revision = `git log --pretty=oneline | wc -l`
	sh "defaults write `pwd`/markbook/MarkBook.xcodeproj-Info CFBundleVersion %s" % revision
	sh "git add -u"
	sh "git ci --amend"
end

task :xcode do |t|
	sh "xcodebuild"
    File.directory?"/tmp/MarkBook" or `mkdir /tmp/MarkBook`
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

task :zip do |t|
	tag = `git describe --tag`.rstrip
	filename= "MarkBook_%s.zip" % tag
	sh "zip -r ~/Downloads/%s /tmp/MarkBook/MarkBook.app > /dev/null" % filename
	signature = IO.popen("sign_update.rb ~/Downloads/%s ~/.ssh/dsa_priv.pem" % filename).gets().rstrip
    version_str = `defaults read \`pwd\`/markbook/MarkBook.xcodeproj-Info CFBundleShortVersionString`.rstrip
    version = `defaults read \`pwd\`/markbook/MarkBook.xcodeproj-Info CFBundleVersion`.rstrip
	length = IO.popen("stat -f %%z ~/Downloads/%s" % filename).gets().rstrip

    str = '
<item> 
    <title>MarkBook %s(%s)</title> 
    <description><![CDATA[ 
        <h2> MarkBook %s(%s) Changelog</h2> 
        <ul> 
            <li> [NEW] </li>
            <li> [FIX] </li>
        </ul>
    ]]></description> 
    <pubDate>%s</pubDate> 
    <enclosure url="https://amoblin.googlecode.com/files/%s" sparkle:shortVersionString="%s" sparkle:version="%s" length="%s" type="application/octet-stream" sparkle:dsaSignature="%s" /> 
</item>
    ' % [version_str, version, version_str, version, `date`.rstrip, filename, version_str, version, length, signature]
    puts str
	#sh 'git log --pretty=oneline | wc -l'
end

task :run => :xcode do |t|
	`build/Release/MarkBook.app/Contents/MacOS/MarkBook`
end