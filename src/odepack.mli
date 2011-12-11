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

(** Binding to ODEPACK.  This is a collection of solvers for the
    initial value problem for ordinary differential equation systems.

    @author Christophe Troestler (Christophe.Troestler\@umons.ac.be)
*)

open Bigarray

type vec = (float, float64_elt, fortran_layout) Array1.t
(** Representation of vectors (parametrized by their layout). *)

type mat = (float, float64_elt, fortran_layout) Array2.t
(** Representation of matrices (parametrized by their layout). *)

type t
(** A mutable value holding the current state of solving the ODE. *)

(** Types of Jacobian matrices. *)
type jacobian =
  | Auto_full (** Internally generated (difference quotient) full Jacobian *)
  | Auto_band of int * int
  (** Internally generated (difference quotient) band Jacobian.  It
      takes [(l,u)] where [l] (resp. [u]) is the number of lines below
      (resp. above) the diagonal (excluded). *)
  | Full of (float -> vec -> mat -> unit)
  (** [Full df] means that a function [df] is provided to compute the
      full Jacobian matrix (∂f_i/∂y_j) of the vector field f(t,y).
      [df t y jac] must store ∂f_i/∂y_j([t],[y]) into [jac.{i,j}]. *)
  | Band of int * int * (float -> vec -> int -> mat -> unit)
  (** [Band(l, u, df)] means that a function [df] is provided to compute
      the banded Jacobian matrix with [l] (resp. [u]) diagonals below
      (resp. above) the main one (not counted).  [df t y d jac] must
      store ∂f_i/∂y_j([t],[y]) into [jac.{i-j+d, j}].  [d] is the row of
      [jac] corresponding to the main diagonal of the Jacobian matrix.  *)

val lsoda : ?rtol:float -> ?rtol_vec:vec -> ?atol:float -> ?atol_vec:vec ->
  ?jac:jacobian -> ?mxstep:int -> ?copy_y0:bool ->
  ?debug:bool -> ?debug_switches:bool ->
  (float -> vec -> vec -> unit) -> vec -> float -> float -> t
(** [lsoda f y0 t0 t] solves the ODE dy/dt = F(t,y) with initial
    condition y([t0]) = [y0].  The execution of [f t y y'] must
    compute the value of the F([t], [y]) and store it in [y'].

    @param rtol  relative error tolerance parameter.  Default [1e-6].
    @param rtol_vec  relative error tolerance vector.
    @param atol  absolute error tolerance parameter.  Default [1e-6].
    @param atol_vec  absolute error tolerance vector.

    If [rtol_vec] (resp. [atol_vec]) is specified, it is used in place
    of [rtol] (resp. [atol]).  Specifying only [rtol] (resp. [atol])
    is equivalent to pass a constant [rtol_vec] (resp. [atol_vec]).
    The solver will control the vector E = (E(i)) of estimated local
    errors in [y], according to an inequality of the form
    max-norm(E(i)/EWT(i)) <= 1, where [EWT(i) = rtol_vec.{i} *
    abs_float(y.{i}) +. atol_vec.{i}].

    @param jac is an optional Jabobian matrix.  If the problem is
    expected to be stiff much of the time, you are encouraged to supply
    [jac], for the sake of efficiency.  Default: [Auto_full].

    @param mxstep maximum number of (internally defined) steps allowed
    during one call to the solver.  The default value is 500.

    @param copy_y0 if [false], the vector [y0] is MODIFIED to contain
    the value of the solution at time [t].  Otherwise [y0] is
    unchanged.  Default: [true].

    @param debug allows [lsoda] to print messages.  Default [true].
    The messages contain valuable information, it is not recommended
    to turn them off.

    @param debug_switches prints a message to stdout on each
    (automatic) method switch (between nonstiff and stiff).
    Default: [false].
*)

val vec : t -> vec
(** [vec ode] returns the current value of the solution vector.  *)

val t : t -> float
(** [t ode] returns the current time at which the solution vector was
    computed. *)

val advance : t -> float -> unit
(** [advance ode t] modifies [ode] so that an approximation of the
    value of the solution at times [t] is computed. *)

val sol : t -> float -> vec
(** [sol ode t] modifies [ode] so that it holds an approximation of
    the solution at [t] and returns this approximation. *)
