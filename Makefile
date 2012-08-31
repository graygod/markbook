default: xcode dmg install

xcode:
	xcodebuild

dmg:
	-@mkdir /tmp/MarkBook
	rm -rf /tmp/MarkBook/MarkBook.app
	cp -rf build/Release/markbook.app /tmp/MarkBook/MarkBook.app
	ln -sf /Applications /tmp/MarkBook
	-@rm -rf ~/Downloads/MarkBook.dmg
	hdiutil create ~/Downloads/MarkBook.dmg -srcfolder /tmp/MarkBook

install:
	sudo cp -rf ~/Downloads/MarkBook/MarkBook.app /Applications
