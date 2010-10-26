
open Printf
open Bigarray

let () =
  let y = Array1.of_array float64 fortran_layout [| 0. |] in
  let f _ _ y' = y'.{1} <- 1. in
  let t = 1. in
  ignore(Odepack.lsoda f 0. y t);
  printf "y(t=%g) = %g\n" t y.{1}
