module Haskgine2d.Render.Object where


import Graphics.Rendering.OpenGL (Vector2(..), Color4(..))
import qualified Graphics.Rendering.OpenGL as GL

import Haskgine2d.Render.Shaders (GLProgram)
import qualified Haskgine2d.Render.Shaders as Shaders 

import Data.StateVar (($=!)) 
import Foreign.Storable
import Foreign.Ptr (nullPtr)

import Data.Array.MArray
import Data.Array.Storable

type Position = Vector2 Float
type Color = Color4 Float



{- |
The object that is used for rendering 
-}
data Object = Object {
  program   :: GLProgram,

  position  :: Position,
  rotation  :: Float,
  baseColor :: Color,
  scale     :: GL.Vector2 Float,
  
  vbo       :: GL.VertexArrayObject,
  vao       :: GL.BufferObject,
  ibo       :: GL.BufferObject,
  numIndices :: GL.NumArrayIndices
               
  } deriving (Show, Eq)


toObject :: GLProgram -> [Float] -> [GL.GLushort] -> IO Object
toObject program vertices indices = do
  
  vertexArr <- newListArray (0, length vertices - 1) vertices
  indexArr <- newListArray (0, length indices - 1) indices

  vertexArrayObject <- GL.genObjectName  
  GL.bindVertexArrayObject $=! Just vertexArrayObject

  vertexBufferObject <- GL.genObjectName
  indexBufferObject <- GL.genObjectName
  
  GL.bindBuffer GL.ArrayBuffer $=! Just vertexBufferObject
  withStorableArray vertexArr (\ptr ->
                                GL.bufferData GL.ArrayBuffer $=! (verticesSize, ptr, GL.StaticDraw)
                              )
  GL.vertexAttribPointer (GL.AttribLocation 0) $=! (GL.ToFloat, GL.VertexArrayDescriptor 3 GL.Float 0 nullPtr)
  GL.bindBuffer GL.ElementArrayBuffer $=! Just indexBufferObject
  withStorableArray indexArr (\ptr ->
                               GL.bufferData GL.ElementArrayBuffer $=! (indicesSize, ptr, GL.StaticDraw)
                               )
  return $ Object program (Vector2 0 0) 0 (Color4 0 0 0 1) (Vector2 1 1) vertexArrayObject vertexBufferObject indexBufferObject (fromIntegral $ length indices)
                                                                               
  where
    indicesSize  = fromIntegral $ (length indices) * sizeOf (undefined :: GL.GLushort)
    verticesSize = fromIntegral $ (length vertices) * sizeOf (undefined :: GL.GLfloat)


initObjectDraw :: Object -> IO ()
initObjectDraw obj = do
  GL.currentProgram $=! pure (Shaders.glProgram $ program obj)
  GL.bindVertexArrayObject $=! Just (vbo obj)
  GL.vertexAttribArray (GL.AttribLocation 0) $=! GL.Enabled

setContextUniforms :: Float -> GL.Vector2 Float -> Float -> Object -> IO ()
setContextUniforms time position rotation obj = do
  Shaders.setTime gl time 
  Shaders.setCameraPosition gl position
  Shaders.setCameraRotation gl rotation
  Shaders.setCameraViewMatrics gl $ GL.Vector2 1920 1080
  where
    gl = program obj  


{- |
 This drawing command should only be run when the object has been initiated
-}
drawObject :: Object -> IO ()
drawObject obj = do
  Shaders.setObjectPositon gl $ position obj
  Shaders.setObjectRotation gl $ rotation obj
  Shaders.setObjectBaseColor gl $ baseColor obj
  Shaders.setObjectScale gl $ scale obj
 
  GL.drawElements GL.Triangles (numIndices obj) GL.UnsignedShort nullPtr
  return ()      
  where
    gl = program obj
  
 
