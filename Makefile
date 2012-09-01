default: xcode dmg install

revision:
	defaults write `pwd`/markbook/MarkBook.xcodeproj-Info CFBundleVersion `git log --pretty=oneline | wc -l`

xcode:
	xcodebuild

dmg:
	-@mkdir /tmp/MarkBook
	rm -rf /tmp/MarkBook/MarkBook.app
	cp -rf build/Release/MarkBook.app /tmp/MarkBook/MarkBook.app
	ln -sf /Applications /tmp/MarkBook
	-@rm -rf ~/Downloads/MarkBook.dmg
	hdiutil create ~/Downloads/MarkBook.dmg -srcfolder /tmp/MarkBook

install:
	sudo cp -rf /tmp/MarkBook/MarkBook.app /Applications
