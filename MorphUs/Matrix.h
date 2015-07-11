//----------------------------------------------------------------------------------
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/ Template Matrix Class \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//----------------------------------------------------------------------------------
//		By Dan Shepherd, October 2003.
//		Works with ints, floats and doubles. (Would not try inverting an int matrix)
//	>>>	Note, this class uses index values starting (0,0) not (1,1).
//		Note 2: LUDecomposition/LUBackSubstitution routines adapted to C++
//				from original C versions developed by authors of
//				"Numerical Recipes in C (Cambridge Press)"
//----------------------------------------------------------------------------------

#pragma once

#include <math.h>
#include <iostream>

using namespace std;

#define TINY 1.0e-20
#define PI 3.141592654

//----------------------------------------------------------------------------------
//	Matrix class
//----------------------------------------------------------------------------------
template<class T> class Matrix
{
private:
	int rows;
	int cols;
	T* p;
public:
	// Exception classes
	class Range{};
	class Square{};
	class Singular{};
	class NoInverse{};
    class MallocError{};
	// Construction/Destruction
	Matrix();
	Matrix(Matrix<T>&);
	Matrix(int r, int c);
	~Matrix();
	// Basic operators
	Matrix<T>&			operator=(Matrix<T>&);
	Matrix<T>&			operator=(T);
	Matrix<T>&			operator+=(T);
	Matrix<T>&			operator+=(Matrix<T>&);
	Matrix<T>			operator+(Matrix<T>&);
	Matrix<T>&			operator-=(T);
	Matrix<T>&			operator-=(Matrix<T>&);
	Matrix<T>			operator-(Matrix<T>&);
	Matrix<T>&			operator*=(T);
	Matrix<T>&			operator*=(Matrix<T>&);
	Matrix<T>			operator*(Matrix<T>&);
	Matrix<T>			operator*(T);
	// Matrix content functions
	int			Rows();
	int			Cols();
	Matrix<T>&			FromArray(int r, int c, T *a);
	T*					GetContents();
	T&					Element(int i, int j);
	Matrix<T>&			Unit();
	// Matrix inversion deteminant
	Matrix<T>&			LUDecomp(int *indx, T *d);
	Matrix<T>&			LUBackSub(int *indx, T *b);
	Matrix<T>&			Inverse(T *d);
	Matrix<T>&			Inverse();
	T					Determinant();
	// Vector operations
	Matrix<T>			CrossProduct(Matrix<T>& v);
	T					DotProduct(Matrix<T>& v);
	T					Magnitude();
	Matrix<T>&			Normalize();
	// Matrix manipulation functions
	Matrix<T>			Transpose();
	Matrix<T>			SubMat(int r, int c, int h, int w);
	Matrix<T>			ConcHoriz(Matrix<T>& m);
	Matrix<T>			ConcVert(Matrix<T>& m);
	Matrix<T>&			Paste(Matrix<T>& m, int r, int c);
	// Exception function to check for square matrix
	inline void			IsSquare(){if(rows!=cols) throw Square();};
	// Matrix transform functions
	static inline T		DegToRad(T angle){return (T)(angle/180.0*PI);};
	Matrix<T>&			CreateRotX(T angle);
	Matrix<T>&			CreateRotY(T angle);
	Matrix<T>&			CreateRotZ(T angle);
	Matrix<T>&			CreateRotXRad(T angle);
	Matrix<T>&			CreateRotYRad(T angle);
	Matrix<T>&			CreateRotZRad(T angle);
	Matrix<T>&			Translate(T tx, T ty, T tz);
	Matrix<T>&			Scale(T sx, T sy, T sz);
	// Matrix I/O operators
	friend ostream&		operator<<<T>(ostream&, Matrix<T>&);
	friend istream&		operator>><T>(istream&, Matrix<T>&);
};



