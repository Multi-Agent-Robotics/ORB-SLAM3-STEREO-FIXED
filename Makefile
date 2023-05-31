

all: vocabulary/ORBvoc.txt

# decompress vocabulary
vocabulary/ORBvoc.txt:
	tar -xzf vocabulary/ORBvoc.txt.tar.gz -C vocabulary


.PHONY: clean
# clean
clean:
	rm -rf vocabulary/ORBvoc.txt
