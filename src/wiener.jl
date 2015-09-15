type Wiener{T}  <: CTPro{T}
end
type WienerBridge{T}  <: CTPro{T}
    t::Float64
    v::T
end

function sample{T}(tt, P::Wiener{T})
    tt = collect(tt)
    yy = zeros(T,length(tt))
    sample!(CTPath{T}(tt, yy), P)
end

function sample{T}(tt, P::Wiener{T},y1)
    tt = collect(tt)
    yy = zeros(T,length(tt))
    sample!(CTPath{T}(tt, yy), P, y1)
end


function sample!{d,T}(W::CTPath{Vec{d,T}}, P::Wiener{Vec{d,T}}, y1 = W.yy[1])
    sz = d
    W.yy[1] = y1
    yy = mat(W.yy) 
    for i = 2:length(W.tt)
        rootdt = sqrt(W.tt[i]-W.tt[i-1])
        for j = 1:sz
            yy[sz*(i-1) + j] = yy[sz*(i-2) + j] + rootdt*randn()
        end
    end
    CTPath{Vec{d,T}}(W.tt, unmat(Vec{d,T}, yy))
end

function sample!{T}(W::CTPath{T}, P::Wiener{T}, y1 = W.yy[1])
    W.yy[1] = y1
    yy = W.yy
    for i = 2:length(W.tt)
        rootdt = sqrt(W.tt[i]-W.tt[i-1])
        yy[i] = yy[i-1] + rootdt*randn()
    end
    CTPath{T}(W.tt, yy)
end

function sample{T}(tt, P::WienerBridge{T})
    tt = collect(tt)
    yy = zeros(T,length(tt))
    sample!(CTPath{T}(tt, yy), P)
end

function sample{T}(tt, P::WienerBridge{T},y1)
    tt = collect(tt)
    yy = zeros(T,length(tt))
    sample!(CTPath{T}(tt, yy), P, y1)
end

function sample!{d,T}(W::CTPath{Vec{d,T}}, P::WienerBridge{Vec{d,T}}, y1 = W.yy[1])
    
    TT = P.t - W.tt[1]
    sz = d
    W.yy[1] = y1
    v = Vector(P.v)
    yy = mat(W.yy) 
  
    wtotal = zeros(sz)
    for i = 2:length(W.tt)
        rootdt = sqrt(W.tt[i]-W.tt[i-1])
        for j = 1:sz
            wtotal[j] += yy[sz*(i-1) + j] = rootdt*randn()
        end
    end

    # noise between tt[end] and P.t
    rootdt = sqrt(P.t-W.tt[end])
    for j = 1:sz
            wtotal[j] += rootdt*randn() + (yy[j] - v[j])
    end

    # cumsum
    for i = 2:length(W.tt)
        dt = (W.tt[i]-W.tt[i-1])/TT
        for j = 1:sz
            yy[sz*(i-1) + j] = yy[sz*(i-2) + j] + yy[sz*(i-1) + j] - wtotal[j]*dt
        end
    end
    if W.tt[end] == P.t
        yy[:,end] = v
    end
       
    
    CTPath{Vec{d,T}}(W.tt, unmat(Vec{d,T}, yy))
end

function sample!{T}(W::CTPath{T}, P::WienerBridge{T}, y1 = W.yy[1])
    
    TT = P.t - W.tt[1]
    W.yy[1] = y1
    v = P.v
    yy = W.yy
  
    wtotal = zero(T)
    for i = 2:length(W.tt)
        rootdt = sqrt(W.tt[i]-W.tt[i-1])
        wtotal  += yy[i] = rootdt*randn()
    end

    # noise between tt[end] and P.t
    rootdt = sqrt(P.t-W.tt[end])
    wtotal += rootdt*randn() 
    
    # normalize
    wtotal += (yy[1] - v)

    # cumsum
    for i = 2:length(W.tt)
        dt = (W.tt[i]-W.tt[i-1])/TT
        yy[i] = yy[i] + yy[i-1] - wtotal*dt
    end
    if W.tt[end] == P.t
        yy[end] = v
    end
       
    
    CTPath{T}(W.tt, yy)
end

function b{T}(s, x, P::Wiener{T})
    zero(T)
end

function sigma(s, x, P::Wiener)
    I
end


function b(s, x, P::WienerBridge)
    (P.v-x)/(P.t-s)
end

function sigma(s, x, P::WienerBridge)
    I
end


