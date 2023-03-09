#!/usr/bin/env bash

if ! command -v ninja &>/dev/null; then
	echo "ERROR: need ninja build tool installed."
	return 1
fi



echo "Configuring and building Thirdparty/DBoW2 ..."

# cd Thirdparty/DBoW2
pushd Thirdparty/DBoW2 
cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build ./build
popd

#mkdir build
#cd build
#cmake .. -DCMAKE_BUILD_TYPE=Release
#make -j
echo "Configuring and building Thirdparty/g2o ..."

pushd Thirdparty/g2o
cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build ./build
popd

#cd ../../g2o
#mkdir build
#cd build
#cmake .. -DCMAKE_BUILD_TYPE=Release
#make -j


#cd ../../Sophus
echo "Configuring and building Thirdparty/Sophus ..."

pushd Thirdparty/Sophus
cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build ./build
cmake --build ./build --target install # why you do this ORB_SLAM3, why you include this one with abspath and not the others. WHY??
popd


#mkdir build
#cd build
#cmake .. -DCMAKE_BUILD_TYPE=Release
#make -j

#cd ../../../

echo "Uncompress vocabulary ..."

pushd Vocabulary
tar -xf ORBvoc.txt.tar.gz
popd

echo "Configuring and building ORB_SLAM3 ..."

cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build ./build


#mkdir build
#cd build
#cmake .. -DCMAKE_BUILD_TYPE=Release
#make -j4

echo "All done :D"

exit 0