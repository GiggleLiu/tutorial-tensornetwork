using OMEinsum

n = 10
m = randn(ComplexF64, n, n)
n = randn(ComplexF64, n, n)
s = cat(real(m), imag(m), dims=3)
t = cat(real(n), imag(n), dims=3)
c = zeros(2, 2, 2)
c[:, :, 1] = [1 0; 0 -1]
c[:, :, 2] = [0 1; 1 0]

res1 = m * n; res1 = cat(real(res1), imag(res1), dims=3)
res2 = ein"ija,jkb,abc->ikc"(s, t, c)
res1 - res2