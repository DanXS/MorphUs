//
//  GLKMorphViewController.m
//  MorphUs
//
//  Created by Dan Shepherd on 04/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//


// Uniform index.
enum
{
    UNIFORM_UV1,
    UNIFORM_UV2,
    UNIFORM_ALPHA,
    UNIFORM_WEIGHTS1,
    UNIFORM_WEIGHTS2,
    UNIFORM_INTERP_MARKERS,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD1,
    ATTRIB_TEXCOORD2,
    NUM_ATTRIBUTES
};

#import "GLKMorphViewController.h"
#import "MorphLatticeModel.h"
#import "MorphTarget.h"
#import "MorphManager.h"
#import "VideoWriter.h"
#import "ImageUtils.h"

@interface GLKMorphViewController ()
{
    Boolean _isPaused;
    Boolean _isReady;
    Boolean _isExportMode;
    Boolean _shouldExportToWatch;
    Boolean _isExportComplete;
    Boolean _isExportFrameComplete;
    Boolean _hasAborted;
    int _frameNo;
    int _framesPerMorph;
    int _totalFrames;
    ptrdiff_t _morphTargetIndex;
    GLuint _program;
    GLuint _positionVBO;
    GLuint _texcoordVBO1;
    GLuint _texcoordVBO2;
    GLuint _indexVBO;
    GLfloat _alpha;
    GLfloat _weights1[2*84];
    GLfloat _weights2[2*84];
    GLfloat _interpMarkers[2*81];
    UIAlertView* _noMorphTargetsAlertView;
    EAGLContext* _context;
    CGFloat _screenWidth;
    CGFloat _screenHeight;
    MorphLatticeModel* _model;
    GLubyte** _pixelData;
    GLuint _textures[2];
    Boolean _texturesCreated;
    unsigned int _indicesCount;
    MorphManager* _morphManager;
    VideoWriter* _videoWriter;
    CVPixelBufferRef _renderTarget;
    GLubyte* _renderPixels;
    Boolean _hasRenderedFrame;
    int _videoWidth;
    int _videoHeight;
    int _videoFPS;
    WatchUtil* _watchUtil;
    NSString* _uuid;
}
@end


@implementation GLKMorphViewController

@synthesize morphSequence;
@synthesize morphTargets;
@synthesize playBarButtonItem;
@synthesize pauseBarButtonItem;
@synthesize actionIdentifier;
@synthesize movieURL;
@synthesize toolbar;
@synthesize exportAlertView;
@synthesize exportInfoLabel;
@synthesize managedObjectContext;
@synthesize managedObject;

- (void)viewDidLoad
{
    [super viewDidLoad];
    assert(self.managedObjectContext != nil);
    assert(self.managedObject != nil);
    _renderPixels=NULL;
     _texturesCreated=NO;
    _isPaused=NO;
    _isReady=NO;
    _hasRenderedFrame = NO;
    _hasAborted = NO;
    _morphTargetIndex = 0;
    _morphManager = [[MorphManager alloc] init];
    _screenWidth = [UIScreen mainScreen].bounds.size.width;
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    if([self.actionIdentifier isEqual:@"Export"] || [self.actionIdentifier isEqual:@"ExportToWatch"]) {
        _framesPerMorph = 60;
        _videoWidth = 480;
        _videoHeight = 640;
        _videoFPS = 30;
        _shouldExportToWatch = NO;

        NSManagedObject* morphSettings = [self.managedObject valueForKey:@"morphSettings"];
        if(morphSettings != nil)
        {
            _framesPerMorph = [[morphSettings valueForKey:@"framesPerTransition"] intValue];
            _videoFPS = [[morphSettings valueForKey:@"framesPerSecond"] intValue];
        }
        NSLog(@"Export mode");
        _totalFrames = (unsigned int)(_framesPerMorph*(self.morphSequence.count-1));
        if([self.actionIdentifier isEqual:@"ExportToWatch"]) {
            _framesPerMorph = 10;
            _videoWidth = 300;
            _videoHeight = 300;
            _shouldExportToWatch = YES;
            _watchUtil = [[WatchUtil alloc] init];
            _totalFrames = (unsigned int)(_framesPerMorph*(self.morphSequence.count-1));
            _uuid = [WatchUtil storeProjectDescription:self.managedObject noFrames:_totalFrames];
        }
        else {
            [self removeFile:self.movieURL];
        }
        _model = [[MorphLatticeModel alloc] initWithScreenWidth:_screenWidth screenHeight:_screenHeight rows:260 cols:200];
        _indicesCount = [_model getIndicesCount];
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.view.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!_context || ![EAGLContext setCurrentContext:_context]) {
            NSLog(@"Problem with OpenGL context.");
            return;
        }
        self.toolbar.hidden = YES;
        self.exportProgressView.hidden = NO;
        _isExportMode = YES;
        
        _isExportComplete = NO;
        _isExportFrameComplete = YES;
        if (!_shouldExportToWatch) {
            _videoWriter = [[VideoWriter alloc] initWithFileURL:self.movieURL withWidth:_videoWidth andHeight:_videoHeight];
        }
        int nPixels = 4*((int)_screenWidth)*((int)_screenHeight)*sizeof(GLubyte);
        _renderPixels = malloc(nPixels);
    }
    else {
        NSLog(@"Playback mode");
        _framesPerMorph = 60;
        _totalFrames = (unsigned int)(_framesPerMorph*(self.morphSequence.count-1));
        _model = [[MorphLatticeModel alloc] initWithScreenWidth:_screenWidth screenHeight:_screenHeight rows:130 cols:100];
        _indicesCount = [_model getIndicesCount];
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];    // create gles 2.0 context
        if (!_context) {
            NSLog(@"Failed to create ES context");
            return;
        }
        self.toolbar.hidden = NO;
        self.exportProgressView.hidden = YES;
        [self.playBarButtonItem setEnabled:NO];
        [self.pauseBarButtonItem setEnabled:YES];
        _isExportMode = NO;
        _isExportComplete = NO;
        _isExportFrameComplete = YES;
        self.preferredFramesPerSecond = 60;
    }
    GLKView *view = (GLKView *)self.view;
    view.context = _context;
    view.contentScaleFactor = [UIScreen mainScreen].scale;
    [self initPixelBuffers];
    [self setupGL];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
        return YES;
    else
        return NO;
}

- (void)setupBuffers
{
    glGenBuffers(1, &_indexVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, [_model getIndicesCount]*sizeof(GLushort), [_model getIndices], GL_STATIC_DRAW);
    
    glGenBuffers(1, &_positionVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
    glBufferData(GL_ARRAY_BUFFER, [_model getVerticesCount]*sizeof(GLfloat), [_model getVertices], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
    
    glGenBuffers(1, &_texcoordVBO1);
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordVBO1);
    glBufferData(GL_ARRAY_BUFFER, [_model getVerticesCount]*sizeof(GLfloat), [_model getTextureCoords1], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD1);
    glVertexAttribPointer(ATTRIB_TEXCOORD1, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
    
    glGenBuffers(1, &_texcoordVBO2);
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordVBO2);
    glBufferData(GL_ARRAY_BUFFER, [_model getVerticesCount]*sizeof(GLfloat), [_model getTextureCoords2], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD2);
    glVertexAttribPointer(ATTRIB_TEXCOORD2, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:_context];
    [self loadShaders];
    [self setupBuffers];
    glUseProgram(_program);
    glUniform1i(uniforms[UNIFORM_UV1], 0);
    glUniform1i(uniforms[UNIFORM_UV2], 1);
    glUniform1f(uniforms[UNIFORM_ALPHA], 0.0);
}

- (void)tearDownGL
{
    @synchronized(self) {
        [EAGLContext setCurrentContext:_context];
        glDeleteBuffers(1, &_positionVBO);
        glDeleteBuffers(1, &_texcoordVBO1);
        glDeleteBuffers(1, &_texcoordVBO2);
        glDeleteBuffers(1, &_indexVBO);
        if(_texturesCreated) {
            glDeleteTextures(2, _textures);
            _texturesCreated = NO;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        if ([EAGLContext currentContext] == _context) {
            [EAGLContext setCurrentContext:nil];
        }
        if(_renderPixels != NULL)
        {
            free(_renderPixels);
            _renderPixels = NULL;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - image/pixelbuffer/texture methods


-(void)initPixelBuffers
{
    if(self.morphTargets)
    {
        _pixelData = malloc(self.morphTargets.count*sizeof(GLubyte*));
        for(ptrdiff_t i = 0; i < self.morphTargets.count; i++)
        {
            int width = ((MorphTarget*)[self.morphTargets objectAtIndex:i]).image.size.width;
            int height = ((MorphTarget*)[self.morphTargets objectAtIndex:i]).image.size.height;
            CGImageRef imageRef = [((MorphTarget*)[self.morphTargets objectAtIndex:i]).image CGImage];
            _pixelData[i] = [self getPixelData:imageRef Width:width Height:height];
        }
    }
}

-(void)freePixelBuffers
{
    @synchronized(self) {
        if(_pixelData != NULL)
        {
            if(self.morphTargets)
            {
                for(ptrdiff_t i = 0; i < self.morphTargets.count; i++)
                {
                    if(_pixelData[i] != NULL) {
                        free(_pixelData[i]);
                        _pixelData[i] = NULL;
                    }
                }
                _pixelData = NULL;
            }
            
        }
    }
}

-(GLubyte*)getPixelData:(CGImageRef)imageRef Width:(int)width Height:(int)height
{
    GLubyte* textureData = (GLubyte *)malloc(width * height * 4 * sizeof(GLubyte)); // if 4 components per pixel (RGBA)

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(textureData, width, height,
                                             bitsPerComponent, bytesPerRow, colorSpace,
                                             kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    return textureData;
}

-(void)createTexturesFromMorphIndex:(ptrdiff_t)index1 andIndex2:(ptrdiff_t)index2
{
	MorphTarget* morphTarget1 = ((MorphTarget*)self.morphSequence[index1]);
	MorphTarget* morphTarget2 = ((MorphTarget*)self.morphSequence[index2]);
    GLubyte* pixelData1 = NULL;
    GLubyte* pixelData2 = NULL;
    
    // find pixel buffers given morph sequence indexs
    for(ptrdiff_t i = 0; i < self.morphTargets.count; i++)
    {
        if(((MorphTarget*)[self.morphTargets objectAtIndex:i]) == morphTarget1) {
            pixelData1 = _pixelData[i];
        }
        if(((MorphTarget*)[self.morphTargets objectAtIndex:i]) == morphTarget2) {
            pixelData2 = _pixelData[i];
        }
    }
    if(pixelData1==NULL || pixelData2==NULL) {
        NSLog(@"Pixel buffers not found");
        return;
    }

    glDisable(GL_DEPTH_TEST);
    // create texture and bind texture 0
    glGenTextures(1, &_textures[0]);
    glBindTexture(GL_TEXTURE_2D, _textures[0]);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, morphTarget1.image.size.width, morphTarget1.image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelData1);
    
    // create texture and bind texture 1
    glGenTextures(1, &_textures[1]);
    glBindTexture(GL_TEXTURE_2D, _textures[1]);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, morphTarget2.image.size.width, morphTarget2.image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelData2);
    _texturesCreated=YES;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    @synchronized(self)
    {
        if(_hasAborted)
            return;
        if(_frameNo < _totalFrames) {
            if(_isExportMode && _hasRenderedFrame) {
                if(_shouldExportToWatch) {
                    [self sampleAndExportToWatchPixelBufferForFrame:_frameNo];
                }
                else {
                    [self sampleAndExportPixelBufferForFrame:_frameNo];
                }
            }
            _morphTargetIndex = _frameNo / _framesPerMorph;
            _alpha = ((float)_frameNo /(float)_framesPerMorph) - _morphTargetIndex;
            if(_frameNo % _framesPerMorph == 0) {
                [_morphManager setSourceMakers:((MorphTarget*)self.morphSequence[_morphTargetIndex]).markers
                                andDestMarkers:((MorphTarget*)self.morphSequence[_morphTargetIndex+1]).markers];
                if(_texturesCreated) {
                    glDeleteTextures(2, _textures);
                }
                [self createTexturesFromMorphIndex:_morphTargetIndex andIndex2:_morphTargetIndex+1];
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, _textures[0]);
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, _textures[1]);
            }
            if(_morphManager) {
                [_morphManager doMorph:_alpha forSrcWeights:_weights1 andDestWeights:_weights2 InterpolatedMarkers:_interpMarkers];
                glUniform2fv(uniforms[UNIFORM_INTERP_MARKERS], 81, _interpMarkers);
                glUniform2fv(uniforms[UNIFORM_WEIGHTS1], 84, _weights1);
                glUniform2fv(uniforms[UNIFORM_WEIGHTS2], 84, _weights2);
                glUniform1f(uniforms[UNIFORM_ALPHA], _alpha);
                _isReady = YES;
            }
        }
        else {
            if(_isExportMode && !_isPaused)
            {
                if(_shouldExportToWatch) {
                    [self sampleAndExportToWatchPixelBufferForFrame:_frameNo];
                }
                else {
                    [self sampleAndExportPixelBufferForFrame:_frameNo];
                }
                _isExportComplete = YES;
                _isExportMode = NO;
                _isPaused = YES;
                if (_shouldExportToWatch) {
                    [self presentExportCompletedAlert:@"Export completed successfully"];
                }
                else {
                    __weak GLKMorphViewController* weakSelf = self;
                    [_videoWriter waitForComplete:^(BOOL complete) {
                        if(complete)
                        {
                            [weakSelf saveMovieToCameraRoll];
                            [weakSelf presentExportCompletedAlert:@"Export completed successfully"];
                        }
                        else
                        {
                            [weakSelf removeFile:weakSelf.movieURL];
                            [weakSelf presentExportCompletedAlert:@"Export failed"];
                        }
                    }];
                }
                
                glUniform1f(uniforms[UNIFORM_ALPHA], 1.0);
                [self.playBarButtonItem setEnabled:YES];
                [self.pauseBarButtonItem setEnabled:NO];
            }
        }
        if(!_isPaused)
            _frameNo++;
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    @synchronized(self) {
        if(_hasAborted)
            return;
        glClear(GL_COLOR_BUFFER_BIT);
        glClearColor(0.0, 0.0, 0.0, 1.0);
        if (_model && _texturesCreated && _isReady)
        {
            glDrawElements(GL_TRIANGLE_STRIP, _indicesCount, GL_UNSIGNED_SHORT, 0);
            if(_isExportMode)
                _hasRenderedFrame = YES;
        }
    }
}

#pragma mark - Export to watch methods

- (void)sampleAndExportToWatchPixelBufferForFrame:(int)frame {
    @synchronized(self)
    {
        UIImage* image = [((GLKView*)self.view) snapshot];
        UIImage* scaledImage;
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]) {
            // Retina display
            scaledImage = [ImageUtils resizeImage:image scale:[UIScreen mainScreen].scale newSize:CGSizeMake(300.0, 300.0)];;
            
        } else {
            // non-Retina display
            scaledImage = [ImageUtils resizeImage:image scale:1.0 newSize:CGSizeMake(300.0, 300.0)];
        }
        while(!_isExportFrameComplete)
            [NSThread sleepForTimeInterval:0.02];
        self.exportInfoLabel.text = [NSString stringWithFormat:@"Exporting Frame: %d", frame];
        self.exportProgressBarView.progress = (float)frame/(float)_totalFrames;
        // store frame to sync with watch app
        NSLog(@"frame number %d", frame);
        [WatchUtil storeFrame:frame uuid:_uuid image:scaledImage];
        _isExportFrameComplete = YES;
    }
}

#pragma mark - Export methods


- (void)sampleAndExportPixelBufferForFrame:(int)frame
{
    @synchronized(self)
    {
        UIImage* image = [((GLKView*)self.view) snapshot];
        UIImage* scaledImage;
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]) {
            // Retina display
            scaledImage = [ImageUtils resizeImage:image scale:[UIScreen mainScreen].scale newSize:CGSizeMake(_videoWidth, _videoHeight)];
            
        } else {
            // non-Retina display
            scaledImage = [ImageUtils resizeImage:image scale:1.0 newSize:CGSizeMake(_videoWidth, _videoHeight)];
        }
        while(!_isExportFrameComplete)
            [NSThread sleepForTimeInterval:0.02];
        _renderTarget = [ImageUtils pixelBufferFromCGImage:scaledImage.CGImage withWidth:_videoWidth andHeight:_videoHeight];
        self.exportInfoLabel.text = [NSString stringWithFormat:@"Exporting Frame: %d", frame];
        self.exportProgressBarView.progress = (float)frame/(float)_totalFrames;
        // grab the pixels
        _isExportFrameComplete = NO;
        CVPixelBufferLockBaseAddress(_renderTarget, 0);
        // write pixels data to movie stream
        CMTime frameTime = CMTimeMake(1, _videoFPS);
        CMTime lastTime=CMTimeMake(frame, _videoFPS);
        NSLog(@"frame number %d", frame);
        CMTime presentTime=CMTimeAdd(lastTime, frameTime);
        [_videoWriter writePixels:_renderTarget withPresentationTime:presentTime];
        CVPixelBufferUnlockBaseAddress(_renderTarget,0);
        CVPixelBufferRelease(_renderTarget);
        _isExportFrameComplete = YES;
    }
}

- (void)presentExportCompletedAlert:(NSString*)message
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.exportProgressView.hidden = YES;
        self.exportAlertView = [[UIAlertView alloc]
                            initWithTitle:@"Finished"
                            message:message
                            delegate:self
                            cancelButtonTitle:@"OK!"
                            otherButtonTitles:nil];
        [self.exportAlertView show];
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    @synchronized(self) {
    if(alertView==exportAlertView)
        {
            _isReady = NO;
            _hasAborted = YES;
            [self tearDownGL];
            [self freePixelBuffers];
            [_model freebuffers];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)removeFile:(NSURL *)fileURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [fileURL path];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
		if (!success)
			NSLog(@"Error removing temp movie file");
    }
}

- (void)saveMovieToCameraRoll
{
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library writeVideoAtPathToSavedPhotosAlbum:self.movieURL
								completionBlock:^(NSURL *assetURL, NSError *error) {
									if (error)
										NSLog(@"Save movie to camera roll failed");
									else
                                    {
										NSLog(@"Saved movie to camera roll");
                                        [self saveMovieURL:assetURL];
                                    }
                                    [self removeFile:self.movieURL];
								}];
}

- (void)saveMovieURL:(NSURL*)url
{
    NSManagedObject* morphSettings = [self.managedObject valueForKey:@"morphSettings"];
    [morphSettings setValue:url.absoluteString forKey:@"videoURL"];
    
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error]) {
        if (error) {
            NSLog(@"Unable to save record.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        
        // Show Alert View
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Video URL could not be saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "Position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD1, "TexCoord1");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD2, "TexCoord1");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_UV1] = glGetUniformLocation(_program, "SamplerUV1");
    uniforms[UNIFORM_UV2] = glGetUniformLocation(_program, "SamplerUV2");
    uniforms[UNIFORM_ALPHA] = glGetUniformLocation(_program, "Alpha");
    uniforms[UNIFORM_WEIGHTS1] = glGetUniformLocation(_program, "Weights1");
    uniforms[UNIFORM_WEIGHTS2] = glGetUniformLocation(_program, "Weights2");
    uniforms[UNIFORM_INTERP_MARKERS] = glGetUniformLocation(_program, "InterpMarkers");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#pragma mark - ui actions

- (IBAction)playToggle:(id)sender {
    _isPaused = !_isPaused;
    if(_isPaused)
    {
        [self.playBarButtonItem setEnabled:YES];
        [self.pauseBarButtonItem setEnabled:NO];
    }
    else
    {
        [self.playBarButtonItem setEnabled:NO];
        [self.pauseBarButtonItem setEnabled:YES];
        if(_frameNo >= _totalFrames) {
            _frameNo = 0;
        }
    }
}

- (IBAction)back:(id)sender {
    @synchronized(self) {
        _isReady = NO;
        _hasAborted = YES;
        [self tearDownGL];
        [self freePixelBuffers];
        [_model freebuffers];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)abort:(id)sender {
    @synchronized(self) {
        _isReady = NO;
        _hasAborted = YES;
        [self tearDownGL];
        [self freePixelBuffers];
        [_model freebuffers];
        [self removeFile:self.movieURL];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
