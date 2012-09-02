default: xcode install

revision:
	defaults write `pwd`/markbook/MarkBook.xcodeproj-Info CFBundleVersion `git log --pretty=oneline | wc -l`
	git add -u
	git ci --amend
	make xcode
	make dmg

xcode:
	xcodebuild

pre:
	rm -rf /tmp/MarkBook/MarkBook.app
	cp -rf build/Release/MarkBook.app /tmp/MarkBook/MarkBook.app

dmg: pre
	-@mkdir /tmp/MarkBook
	ln -sf /Applications /tmp/MarkBook
	-@rm -rf ~/Downloads/MarkBook.dmg
	hdiutil create ~/Downloads/MarkBook.dmg -srcfolder /tmp/MarkBook

install: pre
	sudo rm -rf /Applications/MarkBook.app
	sudo cp -rf /tmp/MarkBook/MarkBook.app /Applications
