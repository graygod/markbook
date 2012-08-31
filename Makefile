default: xcode export

xcode:
	xcodebuild

export:
	hdiutil create ~/Downloads/markbook.dmg -srcfolder ~/Library/Developer/Xcode/DerivedData/MarkBook-gbkhbwckcloccjfnsqkfvhjhmnoy/Build/Products/Debug/MarkBook.app -ov 
