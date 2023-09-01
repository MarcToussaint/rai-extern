#!/bin/bash

lib=${@: -1}
git=${HOME}/git
pre=${HOME}/.local

while getopts "gtc" o; do
    case "${o}" in
        g)
            pre=/usr/local
            ;;
        t)
	    git=/tmp/git
	    pre=/tmp/local
            ;;
	c)
	    clean="yes"
	    ;;
	
        *)
            usage
            ;;
    esac
done

mkdir -p ${git}
mkdir -p ${pre}

echo 'Installing' ${lib} ' -- sources:' ${git} ' -- prefix (compiled library):' ${pre}

cd ${git}

case ${lib} in

    botop)
	git clone --single-branch --recurse-submodules https://github.com/MarcToussaint/botop.git
	export PYTHONVERSION=`python3 -c "import sys; print(str(sys.version_info[0])+'.'+str(sys.version_info[1]))"`
	cmake -DPYBIND11_PYTHON_VERSION=$PYTHONVERSION -DCMAKE_INSTALL_PREFIX=${pre} ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;
	
    libfranka)
	git clone --single-branch -b 0.10.0 --recurse-submodules https://github.com/frankaemika/libfranka
	cmake -DCMAKE_INSTALL_PREFIX=${pre} -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    physx)
        git clone --single-branch -b release/104.1 https://github.com/NVIDIA-Omniverse/PhysX.git
        cd PhysX/physx; ./generate_projects.sh linux; cd compiler/linux-release/
	cmake ../../compiler/public -DPX_BUILDPVDRUNTIME=OFF -DPX_BUILDSNIPPETS=OFF -DCMAKE_INSTALL_PREFIX=${pre}
	make install
	;;
    
    librealsense)
	#sudo apt install --yes libusb-1.0-0-dev libglfw3-dev libgtk-3-dev
        git clone --recurse-submodules https://github.com/IntelRealSense/librealsense.git
	cmake -DCMAKE_INSTALL_PREFIX=${pre} -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=OFF ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    eigen)
	git clone --single-branch -b 3.4.0 https://gitlab.com/libeigen/eigen.git
	cmake -DCMAKE_INSTALL_PREFIX=${pre} ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    jsoncpp)
	git clone --single-branch -b 1.9.5 https://github.com/open-source-parsers/jsoncpp.git
	cmake -DCMAKE_INSTALL_PREFIX=${pre} ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    libpng)
	git clone --single-branch -b libpng16 https://github.com/glennrp/libpng.git
	cd libpng; ./configure --prefix=${pre} CFLAGS='-fPIC'
	make install
	;;

    qhull)
	git clone --single-branch -b v7.3.2 https://github.com/qhull/qhull.git
	env CFLAGS="-fPIC" CXXFLAGS="-fPIC" cmake -DCMAKE_INSTALL_PREFIX=${pre} ${lib} -B ${lib}/build2
	make -C ${lib}/build2 install
	cd ${pre}/lib; ln -s libqhullstatic.a libqhull.a; cd ${pre}/include; ln -s libqhull qhull
	;;

    libccd)
	git clone --single-branch -b v2.1 https://github.com/danfis/libccd.git
	env CFLAGS="-fPIC" cmake -DCMAKE_INSTALL_PREFIX=${pre} -DBUILD_SHARED_LIBS=ON ${lib} -B ${lib}/build
	make -C ${lib}/build install
	env CFLAGS="-fPIC" cmake -DCMAKE_INSTALL_PREFIX=${pre} -DBUILD_SHARED_LIBS=OFF ${lib} -B ${lib}/build  #compile shared AND static versions!
	make -C ${lib}/build install
	;;

    fcl)
	git clone --single-branch -b fcl-0.5 https://github.com/flexible-collision-library/fcl.git
        cmake -DCMAKE_INSTALL_PREFIX=${pre} -DFCL_STATIC_LIBRARY=ON -DFCL_BUILD_TESTS=OFF -DFCL_WITH_OCTOMAP=OFF -DCMAKE_CXX_FLAGS="-Wno-deprecated-copy -Wno-class-memaccess -Wno-maybe-uninitialized" ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    glew)
	wget https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.tgz; tar xvzf glew-2.2.0.tgz
	env GLEW_DEST=${pre} make -C glew-2.2.0 install
	;;

    glfw)
	git clone --single-branch -b 3.3-stable https://github.com/glfw/glfw.git
	cmake -DCMAKE_INSTALL_PREFIX=${pre} ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    assimp)
	git clone --single-branch -b v5.2.5 https://github.com/assimp/assimp.git
	cmake -DCMAKE_INSTALL_PREFIX=${pre} -DASSIMP_BUILD_TESTS=OFF -DASSIMP_BUILD_ZLIB=ON -DBUILD_SHARED_LIBS=OFF ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    bullet)
	git clone --single-branch -b 3.08 https://github.com/bulletphysics/bullet3.git bullet
	env CFLAGS="-fPIC" CXXFLAGS="-fPIC" cmake -DBUILD_SHARED_LIBS=OFF -DBUILD_UNIT_TESTS=OFF -DBUILD_OPENGL3_DEMOS=OFF -DBUILD_BULLET2_DEMOS=OFF -DBUILD_EXTRAS=OFF ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    libann)
	git clone --single-branch https://github.com/daveb-dev/libANN.git libann
	make -C ${lib}/src targets "ANNLIB=libANN.a" "C++=g++" "CFLAGS=-O3 -fPIC" "MAKELIB=ar ruv" "RANLIB=true"
	cp -v ${lib}/lib/libANN.a ${pre}/lib; cp -vR ${lib}/include/ANN ${pre}/include
	;;

    opencv)
	git clone --single-branch -b 4.7.0 https://github.com/opencv/opencv.git
	#git clone --single-branch -b 4.7.0 https://github.com/opencv/opencv_contrib.git
	cmake -DCMAKE_INSTALL_PREFIX=${pre} -DWITH_VTK=OFF ${lib} -B ${lib}/build
	make -C ${lib}/build install
	;;

    *)
	echo 'package' ${lib} 'not defined'
esac

cd ${git}

if [ "${clean}" = "yes" -a -e "${lib}/build" ]; then
    echo 'Cleaning' ${lib}/build
    rm -Rf ${lib}/build
fi
