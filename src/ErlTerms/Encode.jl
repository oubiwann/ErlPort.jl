# Copyright (c) 2014, Dreki Þórgísl <dreki@billo.systems>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  * Neither the name of the copyright holders nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
module Encode

export encode, encodeterm, charint4pack, charint2pack

include("Util.jl")

function encode(term; compressed=false)
    encoded = encodeterm(term)
    if compressed
        encoded = vcat(b"P", compressterm(encoded, compressed))
    end
    vcat(b"\x83", encoded)
end

function encodeboolorsym(term)
    str = string(term)
    vcat(b"d", charint2pack(length(str)), convert(Array{Uint8}, str))
end

function encodeterm(term::Symbol)
    encodeboolorsym(term)
end

function encodeterm(term::Nothing)
    encodeboolorsym(:nothing)
end

function encodeterm(term::Bool)
    encodeboolorsym(term)
end

function encodeterm(term::Array{Uint8,1})
    len = length(term)
    if len == 0
        return b"j"
    elseif len <= 65535
        return vcat(b"k", charint2pack(len), term)
    elseif len > 4294967295
        throw(InvalidListLength(len))
    return vcat(b"l", charint4pack(len), map(encodeterm, term), b"j")
    end
end

function encodeterm(term::UTF8String)
    encodeterm(convert(Array{Uint8}, term))
end

function encodeterm(term::Tuple)
    len = length(term)
    if len <= 255
        header = vcat(b"h", convert(Uint8, len))
    elseif arity <= maxtuplesize
        header = charint4pack(arity)
    else
        throw(InvalidTupleArity(arity))
    end
    vcat(header, map(encodeterm, term))
end

end
