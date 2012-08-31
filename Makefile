default: xcode export

xcode:
	xcodebuild

dmg:
	-@mkdir ~/Downloads/MarkBook
	cp -rf ~/Library/Developer/Xcode/DerivedData/MarkBook-gbkhbwckcloccjfnsqkfvhjhmnoy/Build/Products/Debug/MarkBook.app ~/Downloads/MarkBook
	ln -sf /Applications ~/Downloads/MarkBook
	#mkdmg.sh . ~/Downloads/MarkBook/ ~/Downloads MarkBook
	-@rm -rf ~/Downloads/MarkBook.dmg
	hdiutil create ~/Downloads/MarkBook.dmg -srcfolder ~/Downloads/MarkBook
