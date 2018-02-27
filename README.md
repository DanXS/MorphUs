# MorphUs

MorphUs app performs automatic face morphing using facial detection and OpenGL shaders for accelerated playback.
It also exports to video files and apple watch as a series of still images.

It was previously closed source but I've decided to open source it because it uses a face landmark detection model
which is not free for comercial use.

http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2

Previously it used the Face++ API which is no longer free and required a http call to their server.  Note that this
version requires that you uninstall the previous version because Face++ provided 84 landmarks while the dlib version
has 63 facial landmarks.

In terms of the algorithms for morphing it uses the thin plate spline method, thanks to slides from a course I took
at the University of East Anglia provide by my supervisor at the time Dr Rudy Lapeer.

I used a matrix library I had written previously in c++ with algorithms from the book numerical recipies in c but
ported to c++ using templates for types.  But it includes functions for calculating inverse matrices using LU decomposition.

The remainder is in objective C, sorry it's not swift - it is a few years old now.


