//
//  HTView.m
//  OpenGL_IndexMapping
//
//  Created by zhangchi on 8/1/20.
//  Copyright © 2020 Wangqiao. All rights reserved.
//

#import "HTView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>
@interface HTView()

//CAEAGLLayer
@property(nonatomic,strong)CAEAGLLayer *htEagLayer;

//上下文
@property(nonatomic,strong)EAGLContext *htContext;

//渲染缓冲区id
@property(nonatomic,assign)GLuint htColorRenderBuffer;

//帧缓冲区id
@property(nonatomic,assign)GLuint htFrameBuffer;

//着色器程序id
@property(nonatomic,assign)GLuint htProgram;

//顶点缓存区id
@property (nonatomic , assign) GLuint  htVertices;
@end
@implementation HTView
{
    //x轴方向的旋转弧度
    float xDegree;

    //y轴方向的旋转弧度
    float yDegree;

    //z轴方向的旋转弧度
    float zDegree;

    //是否围绕x轴旋转
    BOOL bX;

    //是否围绕y轴旋转
    BOOL bY;

    //是否围绕z轴旋转
    BOOL bZ;

    //定时器
    NSTimer * htTimer;
}

-(void)layoutSubviews
{
        //1.设置图层
    [self setupLayer];

        //2.设置图形上下文
    [self setupContext];


        //3.清空缓存区
    [self deleteRenderAndFrameBuffer];


        //4.设置渲染缓存区RenderBuffer
    [self setupRenderBuffer];


        //5.设置帧缓存区FrameBuffer
    [self setupFrameBuffer];


        //6.开始绘制
    [self renderLayer];

}

    //6 开始绘制
-(void)renderLayer
{
        //1.设置清屏颜色
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
        //清除缓冲区
    glClear(GL_COLOR_BUFFER_BIT);

        //2. 设置视口大小
    GLfloat  scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);

        //3. 读顶点着色器程序和片元着色器程序
    NSString *vertFile = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"fsh"];

    //4.判断self.myProgram是否存在，存在则清空其文件
    if(self.htProgram){
        glDeleteProgram(self.htProgram);
        self.htProgram = 0;
    }
    //5.加载程序到htProgram中来。
    self.htProgram = [self loadShader:vertFile withFrag:fragFile];

        //6. 链接
    glLinkProgram(self.htProgram);


        //7.获取链接状态
    GLint linkStatus;
    glGetProgramiv(self.htProgram, GL_LINK_STATUS, &linkStatus);
    if(linkStatus == GL_FALSE){
        GLchar message[512];
        glGetProgramInfoLog(self.htProgram, sizeof(message), 0, &message[0]);
        NSString *messageString  = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error:%@",messageString);
        return;
    }

    NSLog(@"Programe Link Success!");

        //8. 使用program
    glUseProgram(self.htProgram);

        //9. 创建顶点数组 & 索引数组
        //(1)顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB)

    GLfloat attrArr[] =
    {
    -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,   0.0f, 1.0f,        //左上0
    0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,   1.0f, 1.0f,        //右上1
    0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,   1.0f, 0.0f,        //右下2
    -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,   0.0f, 0.0f,        //左下3
    0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,   0.5f, 0.5f,        //顶点4
    };

        // 索引数组
    GLuint indices[] =
    {
    0, 1, 2,
    0, 2, 3,
    0, 4, 1,
    1, 4, 2,
    2, 4, 3,
    3, 4, 0,
    };


        //(3).判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
    if (self.htVertices == 0) {
        glGenBuffers(1, &_htVertices);
    }


        //10.处理顶点数据
    glBindBuffer(GL_ARRAY_BUFFER, _htVertices);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);

        //11.将顶点数据通过htPrograme中的传递到顶点着色程序的position
        //1).glGetAttribLocation,用来获取vertex attribute的入口的.
    GLuint position = glGetAttribLocation(self.htProgram, "position");

        //(2.设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);

        //3).最后数据是通过glVertexAttribPointer传递过去的。
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, NULL);


    //12.处理顶点颜色值
    //(1).glGetAttribLocation,用来获取vertex attribute的入口的.
    //注意：第二参数字符串必须和shaderv.glsl中的输入变量：positionColor保持一致
    GLuint positionColor = glGetAttribLocation(self.htProgram, "positionColor");
        //(2).设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(positionColor);
    //(3).设置读取方式
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, NULL);

    //13.找到myProgram中的projectionMatrix、modelViewMatrix 2个矩阵的地址。如果找到则返回地址，否则返回-1，表示没有找到2个对象。
    GLuint projectionMatrixID = glGetUniformLocation(self.htProgram, "projectionMatrix");
    GLuint modelViewMatrixID = glGetUniformLocation(self.htProgram, "modelViewMatrix");

        //14.创建4 * 4投影矩阵
    KSMatrix4 _projectionMatrix;
        //(1)获取单元矩阵
    ksMatrixLoadIdentity(&_projectionMatrix);
        //(2)计算纵横比
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = width / height; //长宽比
     //(3)获取透视矩阵
    /*
     参数1：矩阵
     参数2：视角，度数为单位
     参数3：纵横比
     参数4：近平面距离
     参数5：远平面距离
     参考PPT
     */
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f);
       //(4)将投影矩阵传递到顶点着色器
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrixID, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);

        //15.创建一个4 * 4 矩阵，模型视图矩阵
    KSMatrix4 _modelViewMatrix;
        //(1)获取单元矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
        //(2)平移，z轴负方向平移10
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
        //(3)创建一个4 * 4 矩阵，旋转矩阵
    KSMatrix4 _rotationMatrix;
        //(4)初始化为单元矩阵
    ksMatrixLoadIdentity(&_rotationMatrix);
        //(5)旋转
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0); //绕Y轴
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0); //绕Z轴
    //(6)把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结果存放到_modelViewMatrix矩阵中
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
        //(7)将模型视图矩阵传递到顶点着色器
    glUniformMatrix4fv(modelViewMatrixID, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);

    glEnable(GL_BLEND);
        //16.----处理纹理数据-------
        //(1).glGetAttribLocation,用来获取vertex attribute的入口的.
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
    GLuint textCoor = glGetAttribLocation(self.htProgram, "textCoord");

        //(2).设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(textCoor);

        //(3).设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (float *)NULL + 6);

        //17. 加载纹理
    [self setupTexture:@"stone"];

        //设置纹理采样器 sampler2D
    glUniform1f(glGetAttribLocation(self.htProgram, "colorMap"), 0);

        //16.开启剔除操作效果
    glEnable(GL_CULL_FACE);
        //17.使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
     GL_POINTS
     GL_LINES
     GL_LINE_LOOP
     GL_LINE_STRIP
     GL_TRIANGLES
     GL_TRIANGLE_STRIP
     GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
     GL_BYTE
     GL_UNSIGNED_BYTE
     GL_SHORT
     GL_UNSIGNED_SHORT
     GL_INT
     GL_UNSIGNED_INT
     indices：绘制索引数组

     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);

        //18.要求本地窗口系统显示OpenGL ES渲染<目标>
    [self.htContext presentRenderbuffer:GL_RENDERBUFFER];
/*
        //9.----处理纹理数据-------
        //(1).glGetAttribLocation,用来获取vertex attribute的入口的.
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
    GLuint textCoor = glGetAttribLocation(self.htProgram, "textCoordinate");

        //(2).设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(textCoor);

        //(3).设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL + 3);

        //10. 加载纹理
    [self setupTexture:@"kunkun"];

        //11.设置纹理采样器 sampler2D
    GLint textureLocation = glGetUniformLocation(self.htProgram, "colorMap");
    glUniform1i(textureLocation, 0);
 */


}

    //加载纹理
-(GLuint )setupTexture:(NSString *)file
{
        //1.将UIImage 转换为CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:file].CGImage;

        //判断图片是否获取成功
    if(!spriteImage){
        NSLog(@"Failed to load image: %@",file);
        exit(1);
    }

        //2、读取图片的大小，宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);

        //3.获取图片字节数 宽*高*4（RGBA） 开辟存储空间
    GLubyte *spriteData = (GLubyte *)calloc(width*height*4,sizeof(GLubyte));

        //4.创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);

        //5、在CGContextRef上--> 将图片绘制出来
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(spriteContext, rect, spriteImage);

        //6. 画图完毕就释放上下文
    CGContextRelease(spriteContext);

        //7.绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 0);

        //8.设置纹理属性
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        //9.载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);

        //10. 释放spriteData
    free(spriteData);
    return 0;
}

    //加载shader
-(GLuint)loadShader:(NSString *)vert withFrag:(NSString *)frag
{
        //1. 定义两个着色器对象
    GLuint verShader,fragShader;

        //创建 shader;
    GLuint program = glCreateProgram();

        //2. 编译顶点着色器程序和片元着色器程序
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];

        //3.创建最终程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);

        //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);

    return program;

}

    //编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
        //1. 读取文件路径
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar * source  = (GLchar *)[content UTF8String];

        //2. 创建一个shader
    *shader = glCreateShader(type);

        //3.将着色器源码附加到着色器对象上。
        //参数1：shader,要编译的着色器对象 *shader
        //参数2：numOfStrings,传递的源码字符串数量 1个
        //参数3：strings,着色器程序的源码（真正的着色器程序源码）
        //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);

        //4.把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

    //5 设置帧缓存区
-(void)setupFrameBuffer
{
        //1. 定义一个缓存区ID
    GLuint buffer;

        //2. 申请一个缓存区标识
    glGenBuffers(1, &buffer);

        //3. 将buffer赋值给全局变量
    self.htFrameBuffer = buffer;

        //4.将标识符绑定到GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, self.htColorRenderBuffer);

    /*生成帧缓存区之后，则需要将renderbuffer跟framebuffer进行绑定，
     调用glFramebufferRenderbuffer函数进行绑定到对应的附着点上，后面的绘制才能起作用
     */

        //5.将渲染缓存区myColorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 GL_COLOR_ATTACHMENT0上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.htColorRenderBuffer);

}

    //4 设置渲染缓存区RenderBuffer
-(void)setupRenderBuffer
{
        //1. 定义一个缓存区ID
    GLuint buffer;

        //2. 申请一个缓存区标识
    glGenBuffers(1, &buffer);

        //3. 将buffer赋值给全局变量
    self.htColorRenderBuffer = buffer;

        //4.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.htColorRenderBuffer);

        //5.将可绘制对象 CAEAGLLayer的存储绑定到OpenGL ES renderBuffer对象
    [self.htContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.htEagLayer    ];

}

    //3.清空缓存区
-(void)deleteRenderAndFrameBuffer
{
    /*
     buffer分为frame buffer 和 render buffer2个大类。
     其中frame buffer 相当于render buffer的管理者。
     frame buffer object即称FBO。
     render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
     */
    glDeleteBuffers(1, &_htColorRenderBuffer);
    self.htColorRenderBuffer = 0;

    glDeleteBuffers(1, &_htFrameBuffer);
    self.htFrameBuffer = 0;

}

    //2.设置图形上下文
-(void)setupContext
{

        //创建图形上下文
    self.htContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];

        //判断是否创建成功
    if(!self.htContext){
        NSLog(@"create context failed!");
        return;
    }

        //设置当前图形上下文
    if(![EAGLContext setCurrentContext:self.htContext]){
        NSLog(@"setCurrentContext failed!");
        return;
    }


}

    //1.设置图层
-(void)setupLayer
{
        //1.创建特殊图层  重写layerClass，将CCView返回的图层从CALayer替换成CAEAGLLayer
    self.htEagLayer = (CAEAGLLayer *)self.layer;

        //2. 设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];

     //3. 设置opaque
    self.htEagLayer.opaque = YES;

        //4. 设置描述属性
    /************************************************************************/
    /* Keys for EAGLDrawable drawableProperties dictionary                  */
    /*                                                                      */
    /* kEAGLDrawablePropertyRetainedBacking:                                */
    /*  Type: NSNumber (boolean)                                            */
    /*  Legal Values: True/False                                            */
    /*  Default Value: False                                                */
    /*  Description: True if EAGLDrawable contents are retained after a     */
    /*               call to presentRenderbuffer.  False, if they are not   */
    /*                                                                      */
    /* kEAGLDrawablePropertyColorFormat:                                    */
    /*  Type: NSString                                                      */
    /*  Legal Values: kEAGLColorFormat*                                     */
    /*  Default Value: kEAGLColorFormatRGBA8                                */
    /*  Description: Format of pixels in renderbuffer                       */
    /************************************************************************/
    self.htEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys: @false,kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];


}

    //重写图层类
+(Class)layerClass{
    return [CAEAGLLayer class];
}

#pragma mark - XYClick
- (IBAction)XClick:(id)sender {

        //开启定时器
    if (!htTimer) {
        htTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
        //更新的是X还是Y
    bX = !bX;

}
- (IBAction)YClick:(id)sender {

        //开启定时器
    if (!htTimer) {
        htTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
        //更新的是X还是Y
    bY = !bY;
}
- (IBAction)ZClick:(id)sender {

        //开启定时器
    if (!htTimer) {
        htTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
        //更新的是X还是Y
    bZ = !bZ;
}

-(void)reDegree
{
        //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
        //更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
        //重新渲染
    [self renderLayer];

}

@end
