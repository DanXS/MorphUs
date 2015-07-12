//
//  Matrix.cpp
//  MorphUs
//
//  Created by Dan Shepherd on 11/07/2015.
//  Copyright (c) 2015 cuffedtothekeyboard. All rights reserved.
//

#include "Matrix.h"


//----------------------------------------------------------------------------------
//	Construct an empty matrix
//----------------------------------------------------------------------------------
template<class T> Matrix<T>::Matrix()
{
    p = NULL;
    rows = 0;
    cols = 0;
}

//----------------------------------------------------------------------------------
//	Construct copy of another matrix
//----------------------------------------------------------------------------------
template<class T> Matrix<T>::Matrix(Matrix<T>& mat)
{
    int i, j;
    rows = mat.rows;
    cols = mat.cols;
    try {
        p = (T*)malloc(rows*cols*sizeof(T));
        if(p == NULL)
            throw MallocError();
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                Element(i, j) = mat.Element(i, j);
            }
        }
    } catch (Matrix::MallocError) {
        cerr << "Matrix::Matrix caused a memory error!\n";
    }
}

//----------------------------------------------------------------------------------
//	Construct a matrix with r rows and c columns
//----------------------------------------------------------------------------------
template<class T> Matrix<T>::Matrix(int r, int c)
{
    int i;
    rows = r;
    cols = c;
    try {
        p = (T*)malloc(rows*cols*sizeof(T));
        if(p == NULL)
            throw MallocError();
        for(i = 0; i < (r*c); i++)
            p[i] = 0;
    } catch (Matrix::MallocError) {
        cerr << "Matrix::Matrix caused a memory error!\n";
    }
}

//----------------------------------------------------------------------------------
//	Destruct matrix
//----------------------------------------------------------------------------------
template<class T> Matrix<T>::~Matrix()
{
    rows = 0;
    cols = 0;
    if(p != NULL)
        free(p);
    p = NULL;
}

//----------------------------------------------------------------------------------
//	Get number of rows
//----------------------------------------------------------------------------------
template<class T> int Matrix<T>::Rows()
{
    return rows;
}

//----------------------------------------------------------------------------------
//	Get number of columns
//----------------------------------------------------------------------------------
template<class T> int Matrix<T>::Cols()
{
    return cols;
}

//----------------------------------------------------------------------------------
//	Return an element from a matrix. Note index values start at 0 not 1
//----------------------------------------------------------------------------------
template<class T> T& Matrix<T>::Element(int i, int j)
{
    if((i >= 0 && i < rows) &&
       (j >= 0 && j < cols))
        return p[i*cols+j];
    throw Range();
    return p[0];
}

//----------------------------------------------------------------------------------
//	Create a matrix from a one dimensional array
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::FromArray(int r, int c, T *array)
{
    int i;
    rows = r;
    cols = c;
    T *tmpP;
    try {
        if(p != NULL)
            free(p);
        p = (T*)malloc(rows*cols*sizeof(T));
        if(p == NULL)
            throw MallocError();
        tmpP = p;
        for(i = 0; i < r*c; i++)
            *tmpP++ = *array++;
    } catch (Matrix::MallocError) {
        cerr << "Matrix::Matrix caused a memory error!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Return contents of matrix (array only)
//----------------------------------------------------------------------------------
template<class T> T* Matrix<T>::GetContents()
{
    return this->p;
}

//----------------------------------------------------------------------------------
//	Fill a matrix with a given value
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::operator=(T val)
{
    int i;
    int j;
    try
    {
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                Element(i, j) = val;
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::operator=(value) caused a range error!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Matrix assignment operator
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::operator=(Matrix<T>& m)
{
    int i;
    int j;
    try {
        if(p == NULL)
        {
            rows = m.rows;
            cols = m.cols;
            p = (T*)malloc(rows*cols*sizeof(T));
            if(p == NULL)
                throw MallocError();
        }
        if((rows != m.rows) || (cols != m.cols))
        {
            free(p);
            rows = m.rows;
            cols = m.cols;
            p = (T*)malloc(rows*cols*sizeof(T));
            if(p == NULL)
                throw MallocError();
        }
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                Element(i, j) = m.Element(i, j);
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::operator= caused a range error!\n";
    } catch (Matrix::MallocError) {
        cerr << "Matrix::operator= caused a malloc error!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Matrix plus equals operator - (plus value)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::operator+=(T val)
{
    int i;
    int j;
    try
    {
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                Element(i,j) += val;
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::operator+=val caused a range error!";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Matrix plus equals operator
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::operator+=(Matrix<T>& m)
{
    int i;
    int j;
    try
    {
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                Element(i, j) += m.Element(i, j);
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::operator+= caused a range error!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Matrix plus operator
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::operator+(Matrix<T>& m)
{
    
    Matrix<T> tempMat(*this);
    tempMat += m;
    return tempMat;
}

//----------------------------------------------------------------------------------
//	Matrix minus equals operator - (minus value)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::operator-=(T val)
{
    int i;
    int j;
    try
    {
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                Element(i,j) -= val;
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::operator-=val caused a range error!";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Matrix minus equals operator
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::operator-=(Matrix<T>& m)
{
    int i;
    int j;
    try
    {
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                Element(i, j) -= m.Element(i, j);
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::operator-= caused a range error!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Matrix minus operator
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::operator-(Matrix<T>& m)
{
    Matrix<T> tempMat(*this);
    tempMat -= m;
    return tempMat;
}

//----------------------------------------------------------------------------------
//	Matrix times equals operator - (times by value)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::operator*=(T val)
{
    int i;
    int j;
    try
    {
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                Element(i,j) *= val;
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::operator*=val caused a range error!";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Matrix times equals operator
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::operator*=(Matrix<T>& m)
{
    int i;
    int j;
    int k;
    T	temp;
    Matrix<T> tempMat(rows, m.cols);
    try
    {
        if(cols != m.rows) throw Range();
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < m.cols; j++)
            {
                temp = 0;
                for(k = 0; k < cols; k++)
                {
                    temp += Element(i, k) * m.Element(k, j);
                }
                tempMat.Element(i, j) = temp;
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::operator*= caused a range error!\n";
    }
    return *this = tempMat;
}

//----------------------------------------------------------------------------------
//	Matrix times operator
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::operator*(Matrix<T>& m)
{
    
    Matrix<T> tempMat(*this);
    tempMat *= m;
    return tempMat;
}

//----------------------------------------------------------------------------------
//	Matrix times operator - with scaler multiplier
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::operator*(T val)
{
    
    Matrix<T> tempMat(*this);
    tempMat *= val;
    return tempMat;
}

//----------------------------------------------------------------------------------
//	Build a unit matrix - (rows == cols must hold)
//----------------------------------------------------------------------------------
template<class T>	Matrix<T>&	Matrix<T>::Unit()
{
    int i;
    try
    {
        IsSquare();
        *this = 0;
        for(i = 0; i < cols; i++)
            Element(i, i) = 1;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::Unit() - error matrix must be square!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Transpose a matrix
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::Transpose()
{
    int i;
    int j;
    Matrix<T> transMat(cols, rows);
    try
    {
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                transMat.Element(j,i) = Element(i,j);
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::Transpose() - range error!\n";
    }
    return transMat;
}

//----------------------------------------------------------------------------------
//	LU Decomposition
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::LUDecomp(int *indx, T *d)
{
    T* vv = NULL;
    T big, dum, sum, temp;
    int n, i, imax=0, j, k;
    try
    {
        Square();
        n = rows;
        vv = (T*)malloc(n*sizeof(T));
        if(p == NULL)
            throw MallocError();
        *d = 1.0;
        for(i = 0; i < n ; i++)
        {
            big = 0.0;
            for (j = 0; j < n; j++)
                if((temp = ((T)fabs(Element(i,j)))) > big) big = temp;
            if(big == 0.0) throw Singular();
            vv[i]=1.0/big;
        }
        for(j = 0; j < n; j++)
        {
            for(i = 0 ; i < j; i++)
            {
                sum = Element(i,j);
                for(k = 0; k < i; k++) sum -= Element(i,k) * Element(k,j);
                Element(i,j) = sum;
            }
            big = 0.0;
            for (i = j; i < n; i++)
            {
                sum = Element(i,j);
                for(k = 0; k < j; k++)
                    sum -= Element(i, k)*Element(k, j);
                Element(i, j) = sum;
                if((dum = vv[i] * fabs(sum)) >= big)
                {
                    big = dum;
                    imax = i;
                }
            }
            if(j != imax)
            {
                for(k = 0; k < n; k++)
                {
                    dum = Element(imax, k);
                    Element(imax, k) = Element(j, k);
                    Element(j, k) = dum;
                }
                *d = -(*d);
                vv[imax]=vv[j];
            }
            indx[j] = imax;
            if(Element(j, j) == (T)0.0) Element(j, j) = (T)TINY;
            if(j != n-1)
            {
                dum = 1.0/Element(j, j);
                for(i = j+1; i < n; i++) Element(i,j) *= dum;
            }
        }
        if(vv != NULL)
            free(vv);
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::LUDecomp - non-square matrix error!\n";
        throw NoInverse();
    }
    catch(Matrix::Singular)
    {
        cerr << "Matrix::LUDecomp - the matrix is singualar!\n";
        throw NoInverse();
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::LUDecomp - range error!\n";
        throw NoInverse();
    }
    catch(Matrix::MallocError)
    {
        cerr << "Matrix::LUDecomp - malloc error!\n";
        throw NoInverse();
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	LU Back Substitution
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::LUBackSub(int *indx, T *b)
{
    int i, ii = -1, ip, j;
    int n = rows;
    T sum;
    try
    {
        for (i = 0; i < n; i++)
        {
            ip = indx[i];
            sum = b[ip];
            b[ip] = b[i];
            if(ii>=0)
                for(j=ii; j<=i-1; j++) sum -= Element(i,j) * b[j];
            else if (sum) ii = i;
            b[i] = sum;
        }
        for (i = n-1; i >= 0; i--)
        {
            sum = b[i];
            for(j = i+1; j < n ; j++) sum -= Element(i, j) * b[j];
            b[i] = sum/Element(i, i);
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::LUBackSub - range error!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Calculate the inverse of a matrix using lu decomposition
//	 - also calculates the determinant while its at it
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::Inverse(T *d)
{
    int i,j;
    int n = rows;
    Matrix<T> inv(n, n);
    try{
        int* indx = (int*)malloc(rows * sizeof(int));
        if(indx == NULL)
            throw MallocError();
        T* col = (T*)malloc(rows * sizeof(T));
        if(col == NULL)
            throw MallocError();
        LUDecomp(indx, d);
        for(j = 0; j < n; j++)
        {
            for(i = 0; i < n; i++) col[i]=0.0;
            col[j] = 1.0;
            LUBackSub(indx, col);
            for(i = 0; i < n; i++) inv.Element(i, j) = col[i];
            *d *= Element(j,j);
        }
        if(indx != NULL)
            free(indx);
        if(col != NULL)
            free(col);
    }
    catch(Matrix::NoInverse)
    {
        cerr << "Matrix::Inverse  error!\n";
    }
    catch(Matrix::MallocError)
    {
        cerr << "Matrix::Inverse malloc error!\n";
    }
    return *this = inv;
}

//----------------------------------------------------------------------------------
//	Calculate the inverse of a matrix using lu decomposition
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::Inverse()
{
    T d;
    this->Inverse(&d);
    return *this;
}

//----------------------------------------------------------------------------------
//	Calculate the determinant of a matrix using lu decomposition
//----------------------------------------------------------------------------------
template<class T> T Matrix<T>::Determinant()
{
    T d;
    int i, n;
    int *indx;
    Matrix<T> tempMat;
    try
    {
        n = rows;
        indx = (int*)malloc(n*sizeof(int));
        Matrix<T> tempMat(*this);
        tempMat.LUDecomp(indx, &d);
        for(i = 0; i < n; i++) d *= tempMat.Element(i,i);
        if(indx != NULL)
            free(indx);
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::Determinant caused a range error!";
    }
    return d;
}

//----------------------------------------------------------------------------------
//	Calculate the cross product of two column vectors
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::CrossProduct(Matrix<T>& v)
{
    Matrix<T> crossVect(rows, cols);
    try
    {
        if(rows != v.rows) throw Range();
        if(cols != v.cols) throw Range();
        if(rows < 3) throw Range();
        if(cols != 1) throw Range();
        crossVect.Element(0,0) =  Element(1,0) * v.Element(2,0)
        - Element(2,0) * v.Element(1,0);
        crossVect.Element(1,0) =  Element(2,0) * v.Element(0,0)
        - Element(0,0) * v.Element(2,0);
        crossVect.Element(2,0) =  Element(0,0) * v.Element(1,0)
        - Element(1,0) * v.Element(0,0);
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::CrossProduct caused a range error!";
    }
    return crossVect;
}

//----------------------------------------------------------------------------------
//	Calculate the dot product of two column vectors
//----------------------------------------------------------------------------------
template<class T> T Matrix<T>::DotProduct(Matrix<T>& v)
{
    int i;
    T dot = 0;
    try
    {
        if(rows != v.rows) throw Range();
        if(cols != v.cols) throw Range();
        if(cols != 1) throw Range();
        for(i = 0; i < rows; i++)
        {
            dot += Element(i,0) * v.Element(i,0);
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::DotProduct caused a range error!\n";
    }
    return dot;
}

//----------------------------------------------------------------------------------
//	Calculate the magnitude of a vector
//----------------------------------------------------------------------------------
template<class T>T Matrix<T>::Magnitude()
{
    return sqrt(DotProduct(*this));
}

//----------------------------------------------------------------------------------
//	Normalise a vector
//----------------------------------------------------------------------------------
template<class T>Matrix<T>& Matrix<T>::Normalize()
{
    T	invmag = (T)0;
    T	dot;
    try
    {
        dot = DotProduct(*this);
        if(dot>0)
        {
            invmag = 1/sqrt(dot);
            *this *= invmag;
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::Normalise caused a range error!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Get a sub matrix from a source matrix - wraps row and col values if needed
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::SubMat(int r, int c, int h, int w)
{
    int si, sj, di, dj;
    Matrix<T> subMat(h,w);
    try
    {
        for(di = 0, si = r; di < h; di++, si++)
        {
            if(si >= rows) si  = 0;
            for(dj = 0, sj = c; dj < w; dj++, sj++)
            {
                if(sj >= cols) sj = 0;
                subMat.Element(di,dj) = Element(si,sj);
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::SubMat caused a range error!\n";
    }
    return subMat;
}

//----------------------------------------------------------------------------------
//	Concatinate two matrices horizontally
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::ConcHoriz(Matrix<T>& m)
{
    int i, j;
    int w = cols + m.cols;
    int h = rows;
    Matrix<T> concMat(h,w);
    try
    {
        if(rows != m.rows) throw Range();
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                concMat.Element(i,j) = Element(i,j);
            }
        }
        for(i = 0; i < m.rows; i++)
        {
            for(j = 0; j < m.cols; j++)
            {
                concMat.Element(i,cols+j) = m.Element(i,j);
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::ConcHoriz caused a range error!\n";
    }
    return concMat;
}

//----------------------------------------------------------------------------------
//	Concatinate two matrices vertically
//----------------------------------------------------------------------------------
template<class T> Matrix<T> Matrix<T>::ConcVert(Matrix<T>& m)
{
    int i, j;
    int w = cols;
    int h = rows + m.rows;
    Matrix<T> concMat(h, w);
    try
    {
        if(cols != m.cols) throw Range();
        for(i = 0; i < rows; i++)
        {
            for(j = 0; j < cols; j++)
            {
                concMat.Element(i,j) = Element(i,j);
            }
        }
        for(i = 0; i < m.rows; i++)
        {
            for(j = 0; j < m.cols; j++)
            {
                concMat.Element(rows+i,j) = m.Element(i,j);
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::ConcVert caused a range error!\n";
    }
    return concMat;
}

//----------------------------------------------------------------------------------
//	Paste the contents of one matrix into another
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::Paste(Matrix<T>& m, int r, int c)
{
    int i, j;
    try
    {
        for(i = 0; i < m.rows; i++)
        {
            for(j = 0; j < m.cols; j++)
            {
                Element(r+i, c+j) = m.Element(i, j);
            }
        }
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::Paste caused a range error!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Create a rotation matrix to rotate around the X axis (in degrees)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::CreateRotX(T angle)
{
    T cos_val, sin_val;
    try
    {
        Square();
        if((rows != 4) || (cols != 4))
            throw Range();
        Unit();
        cos_val = (T)cos((double)DegToRad(angle));
        sin_val = (T)sin((double)DegToRad(angle));
        Element(1, 1) = cos_val;
        Element(2, 2) = cos_val;
        Element(1, 2) = -sin_val;
        Element(2, 1) = sin_val;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::CreateRotX matrix not square!\n";
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::CreateRotX matrix must be 4x4!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Create a rotation matrix to rotate around the Y axis (in degrees)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::CreateRotY(T angle)
{
    T cos_val, sin_val;
    try
    {
        Square();
        if((rows != 4) || (cols != 4))
            throw Range();
        Unit();
        cos_val = (T)cos((double)DegToRad(angle));
        sin_val = (T)sin((double)DegToRad(angle));
        Element(0, 0) = cos_val;
        Element(2, 2) = cos_val;
        Element(0, 2) = sin_val;
        Element(2, 0) = -sin_val;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::CreateRotY matrix not square!\n";
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::CreateRotY matrix must be 4x4!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Create a rotation matrix to rotate around the Z axis (in degrees)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::CreateRotZ(T angle)
{
    T cos_val, sin_val;
    try
    {
        Square();
        if((rows != 4) || (cols != 4))
            throw Range();
        Unit();
        cos_val = (T)cos((double)DegToRad(angle));
        sin_val = (T)sin((double)DegToRad(angle));
        Element(0, 0) = cos_val;
        Element(1, 1) = cos_val;
        Element(0, 1) = -sin_val;
        Element(1, 0) = sin_val;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::CreateRotZ matrix not square!\n";
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::CreateRotZ matrix must be 4x4!\n";
    }
    return *this;
}
//----------------------------------------------------------------------------------
//	Create a rotation matrix to rotate around the X axis (in radians)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::CreateRotXRad(T angle)
{
    T cos_val, sin_val;
    try
    {
        Square();
        if((rows != 4) || (cols != 4))
            throw Range();
        Unit();
        cos_val = (T)cos((double)angle);
        sin_val = (T)sin((double)angle);
        Element(1, 1) = cos_val;
        Element(2, 2) = cos_val;
        Element(1, 2) = -sin_val;
        Element(2, 1) = sin_val;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::CreateRotX matrix not square!\n";
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::CreateRotX matrix must be 4x4!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Create a rotation matrix to rotate around the Y axis (in radians)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::CreateRotYRad(T angle)
{
    T cos_val, sin_val;
    try
    {
        Square();
        if((rows != 4) || (cols != 4))
            throw Range();
        Unit();
        cos_val = (T)cos((double)angle);
        sin_val = (T)sin((double)angle);
        Element(0, 0) = cos_val;
        Element(2, 2) = cos_val;
        Element(0, 2) = sin_val;
        Element(2, 0) = -sin_val;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::CreateRotY matrix not square!\n";
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::CreateRotY matrix must be 4x4!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Create a rotation matrix to rotate around the Z axis (in radians)
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::CreateRotZRad(T angle)
{
    T cos_val, sin_val;
    try
    {
        Square();
        if((rows != 4) || (cols != 4))
            throw Range();
        Unit();
        cos_val = (T)cos((double)angle);
        sin_val = (T)sin((double)angle);
        Element(0, 0) = cos_val;
        Element(1, 1) = cos_val;
        Element(0, 1) = -sin_val;
        Element(1, 0) = sin_val;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::CreateRotZ matrix not square!\n";
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::CreateRotZ matrix must be 4x4!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Create a translation matrix - Note: does not call unit()
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::Translate(T tx, T ty, T tz)
{
    try
    {
        Square();
        if((rows != 4) || (cols != 4))
            throw Range();
        Element(0, 3) = tx;
        Element(1, 3) = ty;
        Element(2, 3) = tz;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::Translate matrix not square!\n";
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::Translate matrix must be 4x4!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Create a scale matrix - Note: does not call unit()
//----------------------------------------------------------------------------------
template<class T> Matrix<T>& Matrix<T>::Scale(T sx, T sy, T sz)
{
    try
    {
        Square();
        if((rows != 4) || (cols != 4))
            throw Range();
        Element(0, 0) = sx;
        Element(1, 1) = sy;
        Element(2, 2) = sz;
    }
    catch(Matrix::Square)
    {
        cerr << "Matrix::Scale matrix not square!\n";
    }
    catch(Matrix::Range)
    {
        cerr << "Matrix::Scale matrix must be 4x4!\n";
    }
    return *this;
}

//----------------------------------------------------------------------------------
//	Display the contents of a matrix to cout
//----------------------------------------------------------------------------------

template<class T> ostream& operator<<(ostream& s, Matrix<T>& m)
{
    int i;
    int j;
    for(i = 0; i < m.Rows(); i++)
    {
        s << "[";
        for(j = 0; j < m.Cols(); j++)
        {
            s << m.Element(i, j);
            s << ((j == m.Cols()-1) ? "]\n" : " ");
        }
    }
    return s;
}

//----------------------------------------------------------------------------------
//	Input Matrix data from cin
//----------------------------------------------------------------------------------
template<class T> istream& operator>>(istream& s, Matrix<T>& m)
{
    int i;
    int j;
    char chr;
    T	num;
    cout << "Input a " << m.Rows() << " rows by " << m.Cols() << " cols matrix:\n";
    for(i = 0; i < m.Rows(); i++)
    {
        do
            s >> chr;
        while (chr != '[');
        for(j = 0; j < m.Cols(); j++)
        {
            s >> num;
            m.Element(i,j) = num;
        }
        do
            s >> chr;
        while (chr != ']');
    }
    return s;
}

template class Matrix<float>;
template class Matrix<double>;
