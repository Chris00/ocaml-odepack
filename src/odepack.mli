(* File: odepack.mli

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3 or
   later as published by the Free Software Foundation, with the special
   exception on linking described in the file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)

(** Binding to ODEPACK. *)

open Bigarray

type 'a vec = (float, float64_elt, 'a) Array1.t
type 'a int_vec = (int, int_elt, 'a) Array1.t

type 'a t

val lsoda : ?rtol:float -> ?atol:float -> ?atol_vec:'a vec ->
  (float -> 'a vec -> 'a vec -> unit) -> float -> 'a vec -> float -> 'a t

val get : 'a t -> 'a vec

val advance : 'a t -> float -> unit
