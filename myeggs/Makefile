default:
	buildout
	patch

buildout: pull
	python bootstrap.py
	bin/build

scripts:
	ln -f eggs/docutils-0.9.1-py2.7.egg/EGG-INFO/scripts/* bin
	chmod 755 bin/*

patch:
	rm -rf eggs/docutils-0.9.1-py2.7.egg/docutils/parsers/rst
	cp -r rst eggs/docutils-0.9.1-py2.7.egg/docutils/parsers/rst
	#cp docutils-patch eggs/docutils-0.9.1-py2.7.egg/docutils/parsers/rst/
	#cd eggs/docutils-0.9.1-py2.7.egg/docutils/parsers/rst;patch -p1 < docutils-patch

pull:
	rm -rf rst
	cp -r eggs/docutils-0.9.1-py2.7.egg/docutils/parsers/rst .

clean:
	rm -rf bin develop-eggs eggs parts

export:
	find .|grep pyc$$|xargs rm -f
	rm -rf ~/Downloads/myeggs
	cp -r . ~/Downloads/myeggs
