default: xcode install

rev:
	defaults write `pwd`/markbook/MarkBook.xcodeproj-Info CFBundleVersion `git log --pretty=oneline | wc -l`
	git add -u
	git ci --amend
	make xcode

xcode:
	@xcodebuild
	@[ -d /tmp/MarkBook ] || mkdir /tmp/MarkBook
	@rm -rf /tmp/MarkBook/MarkBook.app
	@cp -rf build/Release/MarkBook.app /tmp/MarkBook/MarkBook.app

dmg:
	ln -sf /Applications /tmp/MarkBook
	-@rm -rf ~/Downloads/MarkBook.dmg
	hdiutil create ~/Downloads/MarkBook.dmg -srcfolder /tmp/MarkBook

install:
	sudo rm -rf /Applications/MarkBook.app
	sudo cp -rf /tmp/MarkBook/MarkBook.app /Applications

zip: xcode
	@zip -r ~/Downloads/MarkBook_v1.0.zip /tmp/MarkBook/MarkBook.app > /dev/null
	echo
	@sign_update.rb ~/Downloads/MarkBook_v1.0.zip ~/.ssh/dsa_priv.pem
	ls -l ~/Downloads/MarkBook_v1.0.zip

run: xcode
	build/Release/MarkBook.app/Contents/MacOS/MarkBook

test:
