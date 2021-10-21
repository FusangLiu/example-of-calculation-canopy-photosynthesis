function [vertex,face] = read_ply(filename)

% read_ply - read data from PLY file.
%
%   [vertex,face] = read_ply(filename);
%
%   'vertex' is a 'nb.vert x 3' array specifying the position of the vertices.
%   'face' is a 'nb.face x 3' array specifying the connectivity of the mesh.
%
%   IMPORTANT: works only for triangular meshes.
%
%   Copyright (c) 2003 Gabriel Peyr

[d,c] = plyread(filename);

vi = d.face.vertex_indices;
nf = length(vi);
face = zeros(nf,3);
for i=1:nf
    face(i,:) = vi{i}+1;
end

vertex = [d.vertex.x, d.vertex.y, d.vertex.z];
