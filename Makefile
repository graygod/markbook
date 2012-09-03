default: xcode install

rev:
	defaults write `pwd`/markbook/MarkBook.xcodeproj-Info CFBundleVersion `git log --pretty=oneline | wc -l`
	git add -u
	git ci --amend
	make xcode

xcode:
	xcodebuild

pre:
	-@mkdir /tmp/MarkBook
	rm -rf /tmp/MarkBook/MarkBook.app
	cp -rf build/Release/MarkBook.app /tmp/MarkBook/MarkBook.app

dmg: pre
	ln -sf /Applications /tmp/MarkBook
	-@rm -rf ~/Downloads/MarkBook.dmg
	hdiutil create ~/Downloads/MarkBook.dmg -srcfolder /tmp/MarkBook

install: pre
	sudo rm -rf /Applications/MarkBook.app
	sudo cp -rf /tmp/MarkBook/MarkBook.app /Applications

zip:
	@zip -r MarkBook.zip /tmp/MarkBook/MarkBook.app > /dev/null

sign:
	@sign_update.rb MarkBook.zip ~/.ssh/dsa_priv.pem
