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
(** Representation of vectors (parametrized by their layout). *)

type 'a int_vec = (int, int_elt, 'a) Array1.t
(** Representation of integer vectors (parametrized by their layout). *)

type 'a t
(** A mutable value holding the current state of solving the ODE. *)

val lsoda : ?rtol:float -> ?atol:float -> ?atol_vec:'a vec ->
  (float -> 'a vec -> 'a vec -> unit) -> float -> 'a vec -> float -> 'a t
(** [lsoda f t0 y0 t] solves the ODE dy/dt = F(t,y) with initial
    condition y([t0]) = [y0].  The execution of [f t y y'] must
    compute the value of the F([t], [y]) and store it in [y'].  The
    vector [y0] is MODIFIED to contain the value of the solution at
    time [t].

    @param rtol

    @param atol

    @param atol_vec

    @param jac is an optional Jabobian matrix.  Default: [Auto_full].
*)

val vec : 'a t -> 'a vec
(** [vec ode] returns the current value of the solution vector.  *)

val t : 'a t -> float
(** [t ode] returns the current time at which the solution vector was
    computed. *)

val advance : 'a t -> float -> unit
