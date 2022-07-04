### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 9de3b7ab-14b0-4a79-bd51-6202f7cdfdfd
# ╠═╡ show_logs = false
begin
	import Pkg
    Pkg.activate(mktempdir())
    Pkg.add(Pkg.PackageSpec(url="https://github.com/axelparmentier/InferOpt.jl", rev="giom"))
    Pkg.add(Pkg.PackageSpec(name="ForwardDiff"))
    Pkg.add(Pkg.PackageSpec(name="LaTeXStrings"))
    Pkg.add(Pkg.PackageSpec(name="LinearAlgebra"))
    Pkg.add(Pkg.PackageSpec(name="Plots"))
    Pkg.add(Pkg.PackageSpec(name="PlutoUI"))
    Pkg.add(Pkg.PackageSpec(name="Distributions"))
    Pkg.add(Pkg.PackageSpec(name="Flux"))
    Pkg.add(Pkg.PackageSpec(name="GLPK"))
    Pkg.add(Pkg.PackageSpec(name="Graphs"))
    Pkg.add(Pkg.PackageSpec(name="GridGraphs"))
    Pkg.add(Pkg.PackageSpec(name="Images"))
    Pkg.add(Pkg.PackageSpec(name="JuMP"))
    Pkg.add(Pkg.PackageSpec(name="LinearAlgebra"))
    Pkg.add(Pkg.PackageSpec(name="Plots"))
    Pkg.add(Pkg.PackageSpec(name="PlutoUI"))
    Pkg.add(Pkg.PackageSpec(name="ProgressLogging"))
    Pkg.add(Pkg.PackageSpec(name="Random"))
    Pkg.add(Pkg.PackageSpec(name="SparseArrays"))
    Pkg.add(Pkg.PackageSpec(name="Statistics"))
    Pkg.add(Pkg.PackageSpec(name="TikzPictures"))
	using Distributions
	using Flux
	using ForwardDiff
	using GLPK
	using Graphs
	using GridGraphs
	using InferOpt
	using Images
	using JuMP
	using LaTeXStrings
	using LinearAlgebra
	using Plots
	using PlutoUI
	using ProgressLogging
	using Random
	using SparseArrays
	using Statistics
	using TikzPictures
	Random.seed!(63)
end;

# ╔═╡ 1dbd6f48-d07c-428d-9dad-3bbbf80a73c4
md"""
**Utilities (hidden)**
"""

# ╔═╡ 0cd10bf9-c31e-4f86-833a-f6f64b951015
md"""
Imports
"""

# ╔═╡ 6cf9db2d-f16d-4e4e-a1e4-915d37a2705f
md"""
TOC
"""

# ╔═╡ 0617b570-c163-4bd6-8a6b-e49653c1af7f
TableOfContents(depth=1)

# ╔═╡ 8aa02b43-9c28-4d7e-8eac-551b1e8a4e76
md"""
Figures
"""

# ╔═╡ 5e9486a3-5518-44ad-a9f2-d5371092e46f
fig = TikzPicture(
	L"""
	\tikzset{dummy/.style={fill=green!10, shape=rectangle, draw=black, minimum size=60, font=\Huge, line width=1.5}}
	\tikzset{task/.style={fill=orange!10, shape=circle, draw=black, minimum size=60, font=\Huge, line width=1.5}}
	\tikzset{selected/.style={->, >=stealth, line width=2}}
	\tikzset{redpath/.style={selected, color=red}}
	\tikzset{bluepath/.style={selected, color=blue}}
	\tikzset{purplepath/.style={selected, color=purple}}
	\tikzset{nopath/.style={thick, ->, dashed, line width=2}}
	tikzset{EdgeStyle/.style = {
	  thick,
	  text = black,
	  ->,>=stealth'
	}}
	\node[dummy] (o) at (0,0) {$o$};
	\node[task] (v1) at (5,7.5) {$t_1$};
	\node[task] (v2) at (5,0) {$t_2$};
	\node[task] (v3) at (10,2.5) {$t_3$};
	\node[task] (v4) at (15,10) {$t_4$};
	\node[task] (v5) at (15,5) {$t_5$};
	\node[task] (v6) at (15,0) {$t_6$};
	\node[task] (v7) at (20,7.5) {$t_7$};
	\node[task] (v8) at (20,2.5) {$t_8$};
	\node[dummy] (d) at (25,0) {$d$};
	\draw[redpath] (o) edge (v1);
	\draw[redpath] (v1) edge (v4);
	\draw[redpath] (v4) edge (v7);
	\draw[redpath] (v7) edge (d);
	\draw[bluepath] (o) edge (v3);
	\draw[bluepath] (v3) edge (v5);
	\draw[bluepath] (v5) edge (v8);
	\draw[bluepath] (v8) edge (d);
	\draw[purplepath] (o) edge (v2);
	\draw[purplepath] (v2) edge (v6);
	\draw[purplepath] (v6) edge (d);
	\draw[nopath] (v1) edge (v3);
	\draw[nopath] (v2) edge (v3);
	\draw[nopath] (v3) edge (v4);
	\draw[nopath] (v3) edge (v6);
	\draw[nopath] (v5) edge (v7);
	\draw[nopath] (v6) edge (v8);
	\node[] (time1) at (-1, -2) {};
	\node[] (time2) at (26, -2) {};
	\draw[line width=1.5, ->, >=stealth] (time1) edge node[font=\Huge, below, pos=0.95]{time} (time2);
	""",
	options="scale=1"
);

# ╔═╡ e716f94c-1f4a-4616-bc65-c1e48723bfe3
fig2 = TikzPicture(
	L"""
	\tikzset{node/.style={fill=red!10, shape=rectangle, draw=black, minimum width=100, minimum height=40, font=\LARGE, line width=1.5}}
	\node[node] (t) at (0, 0) {$t$};
	\node[node] (u) at (7, 0) {$u$};
	\node[] (time1) at (-2, -1) {};
	\node[] (time2) at (9, -1) {};
	\draw[<->, line width=1.5] (t) edge node[below]{slack $\Delta_{u,t}$} (u);
	\draw[->, line width=1.5] (time1) edge node[below, pos=0.95]{time} (time2);
	""",
	options="scale=1"
);

# ╔═╡ 954276ad-e5b9-43c2-a969-30410829e778
md"""
Arrow fix
"""

# ╔═╡ a8a40434-4b36-411c-b364-a1056b8295a5
html"""
<script>
    const calculate_slide_positions = (/** @type {Event} */ e) => {
        const notebook_node = /** @type {HTMLElement?} */ (e.target)?.closest("pluto-editor")?.querySelector("pluto-notebook")
		console.log(e.target)
        if (!notebook_node) return []
        const height = window.innerHeight
        const headers = Array.from(notebook_node.querySelectorAll("pluto-output h1, pluto-output h2"))
        const pos = headers.map((el) => el.getBoundingClientRect())
        const edges = pos.map((rect) => rect.top + window.pageYOffset)
        edges.push(notebook_node.getBoundingClientRect().bottom + window.pageYOffset)
        const scrollPositions = headers.map((el, i) => {
            if (el.tagName == "H1") {
                // center vertically
                const slideHeight = edges[i + 1] - edges[i] - height
                return edges[i] - Math.max(0, (height - slideHeight) / 2)
            } else {
                // align to top
                return edges[i] - 20
            }
        })
        return scrollPositions
    }
    const go_previous_slide = (/** @type {Event} */ e) => {
        const positions = calculate_slide_positions(e)
        const pos = positions.reverse().find((y) => y < window.pageYOffset - 10)
        if (pos) window.scrollTo(window.pageXOffset, pos)
    }
    const go_next_slide = (/** @type {Event} */ e) => {
        const positions = calculate_slide_positions(e)
        const pos = positions.find((y) => y - 10 > window.pageYOffset)
        if (pos) window.scrollTo(window.pageXOffset, pos)
    }
	const left_button = document.querySelector(".changeslide.prev")
	const right_button = document.querySelector(".changeslide.next")
	left_button.addEventListener("click", go_previous_slide)
	right_button.addEventListener("click", go_next_slide)
</script>
"""

# ╔═╡ dc635c3b-3bd5-4542-9970-69acb3bfc207
md"""
Two columns
"""

# ╔═╡ d6c80374-a253-4943-98fb-977c6deefa1d
begin
	struct TwoColumn{L, R}
	    left::L
	    right::R
		leftfrac::Int
		rightfrac::Int
	end
	
	function Base.show(io, mime::MIME"text/html", tc::TwoColumn)
		(; left, right, leftfrac, rightfrac) = tc
	    write(io, """<div style="display: flex;"><div style="flex: $(leftfrac)%;">""")
	    show(io, mime, left)
	    write(io, """</div><div style="flex: $(rightfrac)%;">""")
	    show(io, mime, right)
	    write(io, """</div></div>""")
	end
end

# ╔═╡ d487df8f-dc41-4f00-be4e-9d5c4b97e7a4
md"""
Learning
"""

# ╔═╡ ee2daf54-7a9e-4e31-a015-610479671424
dropfirstdim(z::AbstractArray) = dropdims(z; dims=1)

# ╔═╡ 3f003028-ece9-41e6-98c0-3c03652ef3af
function normalized_hamming_distance(x::AbstractArray{<:Real}, y::AbstractArray{<:Real})
    return mean(x[i] != y[i] for i in eachindex(x))
end

# ╔═╡ 25bd7d39-cb39-4bab-879f-54ed98169b34
md"""
Polytope animation
"""

# ╔═╡ eab0af69-82ba-43f1-bc40-7fddfe7b2e12
md"""
# InferOpt.jl: combinatorial optimization in machine learning pipelines

**[Guillaume Dalle](https://gdalle.github.io/), [Léo Baty](https://batyleo.github.io/), [Louis Bouvier](https://louisbouvier.github.io/) & [Axel Parmentier](https://cermics.enpc.fr/~parmenta/)**

CERMICS, École des Ponts
"""

# ╔═╡ 3ff8833b-e8d8-4621-b062-d3065de91ba6
begin
	ptetes = load("./images/tetes.png")
end

# ╔═╡ c820e809-5d03-4073-8326-1fe782decb44
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ 5b6d013f-2d8c-4919-8fe4-4af5219c3634
md"""
# 1. What is it for ?
"""

# ╔═╡ 5cb8738a-7c85-4c88-984e-5a86fcd7acd5
md"""

**Points of view**: 
- Enrich learning pipelines with combinatorial algorithms.
- Enhance combinatorial algorithms with learning pipelines.

```math
\xrightarrow[\text{instance}]{\text{Initial}}
\fbox{ML predictor}
\xrightarrow[\text{instance}]{\text{Encoded}}
\fbox{CO algorithm}
\xrightarrow[\text{solution}]{\text{Candidate}}
\text{Loss}
```

**Challenge:** Differentiating through CO algorithms.

**Two learning settings:**
- Learning by imitation.
- Learning by experience.
"""

# ╔═╡ 04e00283-05c2-4b1b-8c44-54fb1dddb124
md"""
## Many possible applications

- Shortest paths on Warcraft maps $\impliedby$ **today**.
- Stochastic Vehicle Scheduling $\impliedby$ **today**.
- Two-stage Minimum Spanning Tree $\impliedby$ see satellite packages.
- Single-machine scheduling $\impliedby$ see satellite packages.
"""

# ╔═╡ ec6237ae-e7d8-4191-bc2c-8722b7b9fe63
md"""
## Shortest paths on Warcraft maps

Source: [Vlastelica et al. (2020)](https://openreview.net/forum?id=BkevoJSYPB)

**Dataset**: Each point contains

 - an image of a map, where each terrain type has a specific cost
 - a shortest path from the top-left to the bottom-right corners.

**Goal**: Learn to recognize terrain types, in order to find shortest paths from new map images.
"""

# ╔═╡ ad1a47b9-d9d3-4f39-ad8e-7749c651da12
begin
	map = plot(load("./images/Warcraft/map.png"))
	labelpath = plot(load("./images/Warcraft/path.png"))
	plot(map, labelpath, layout = (1,2), ticks = nothing, border = nothing, size = (800, 400))
end

# ╔═╡ f0ee67da-ff8b-4229-a1fc-3be190a2d0b1
md"""
## ML-CO pipeline
"""

# ╔═╡ 4c661db2-312a-4e03-8f66-df2bb68ad9a7
begin
	warcraftpipeline = load("./images/warcraft_pipeline.png")
end

# ╔═╡ 52ca4280-f092-4941-aed5-e3fc25b3149a
md"""
## Test set prediction (1)

We can compare the predicted costs $\theta = \varphi_w(x)$ and the true costs on samples from the test set.
"""

# ╔═╡ 88ba9bb1-02b3-4f32-bf6c-be8f99626f13
begin 
	true_costs = plot(load("./images/Warcraft/costs.png"))
	computed_costs = plot(load("./images/Warcraft/computed_costs.png"))
	plot(map, true_costs, computed_costs, layout = (1,3), ticks = nothing, border = nothing, size = (800, 300))
end

# ╔═╡ 9dee8b4a-451c-4714-8257-9a47b2133002
md"""
## Test set prediction (2)
"""

# ╔═╡ ea2faddf-38b2-46ab-9a53-2057ade1f198
begin 
	computed_path = plot(load("./images/Warcraft/computed_path.png"))
	plot(map, labelpath, computed_path, layout = (1,3), ticks = nothing, border = nothing, size = (800, 300))
end

# ╔═╡ 5f023b91-b0ae-4e91-94fb-f56312c8135f
md"""
## Stochastic Vehicle Scheduling
"""

# ╔═╡ c06b600f-3a79-416e-b2d8-3d85c571d2c8
fig

# ╔═╡ 155ee558-8b6f-446b-adbe-41355e9745c0
md"""
- Set of **delivery tasks** ``t\in T``.
- Predefined time and duration for each task.
- **Decision variables**: schedule of vehicle tours.
- **Constraint**: all tasks must be fulfilled by exactly one vehicle.
"""

# ╔═╡ 0f9a59ac-4a82-4bbd-b662-344491304c53
md"""
## Why "stochastic"?

- Once vehicle tours are set, random delays occur:
  - Set of scenarios ``S``
  - Intrinsic delay of task ``t``: ``\varepsilon_t^s``
  - Slack tasks between tasks ``u`` and ``t``: ``\Delta_{u, t}^s``
  - Delay propagation equation: ``d_t^s = \varepsilon_t^s + \max(d_u^s - \Delta_{u, t}^s, 0)``

- **Objective**: minimize vehicle costs + average delay cost
"""

# ╔═╡ 3dfd513a-d8c0-4e04-aa57-02ee1a63367e
fig2

# ╔═╡ bf2619d5-8f84-4340-9e6f-8343d687fc03
md"""
## MILP formulation
"""

# ╔═╡ 97a8e5d2-85e3-428c-99f0-5348324ea5c6
fig

# ╔═╡ 3e268142-8c00-423f-ab45-abb37e904bb2
md"""
We have the following hard problem: 

```math
(H)\left\{
\begin{aligned}
\min & \frac{1}{|S|} \sum_{s \in S} \sum_{p \in \mathcal{P}}c_p^s y_p &\\

\text{s.t.} & \sum_{p \ni v} y_p = 1 & \forall v \in V \backslash\{o, d\} \quad(\lambda_v \in \mathbb{R})\\

& y_p \in \{0,1\} & \forall p \in \mathcal{P}
\end{aligned}
\right.
```

"""

# ╔═╡ 296fc611-5d26-44c4-8df8-209401a8582a
md"""
## Approximate the hard problem

... with an easier one
```math
(E)\left\{
\begin{aligned}
\min_y &\quad \sum_{a\in\ A}\theta_a y_a\\
\text{s.t.} & \sum_{a\in\delta^-(t)}y_a = \sum_{a\in\delta^+(t)}y_a,\quad & \forall t\in T\\
& \sum_{a\in\delta^+(t)}y_a = 1, & \forall t\in T\\
& y_a\in \{0, 1\}, & \forall a\in A
\end{aligned}
\right.
```

``\implies`` Vehicle Scheduling Problem that can be solved with flow algorithms, or linear programming

Goal: for an instance ``x`` of ``(H)``, find ``\theta(x)`` such that the solution ``\hat y(\theta)`` of ``(E)`` is a good solution of ``(H)``
"""

# ╔═╡ 7c7a76b5-ff7e-4731-96f4-49100d59e03a
md"""
## ML-CO pipeline

```math
\xrightarrow[x \text{ of } (H)]{\text{Instance}}
\fbox{Features $\xi(a, x)$}
\xrightarrow[]{\xi\in \mathbb{R}^{k\times d(x)}}
\fbox{GLM $\xi \mapsto w^\top \xi$}
\xrightarrow[\theta \in \mathbb{R}^{d(x)}]{\text{Cost vector}}
\fbox{Optimizer}
\xrightarrow[y \in \mathcal{Y}(x)]{\text{Solution}}
```

Machine learning predictor:
- ``\theta_a = w^T \xi(a, x)``
- learnable weights ``w``
"""

# ╔═╡ c9cef05b-944b-4595-863d-a0312973d5a3
TikzPicture(L"""
\tikzset{dummy/.style={fill=green!10, shape=rectangle, draw=black, minimum size=60, font=\Huge, line width=1.5}}
\tikzset{task/.style={fill=orange!10, shape=circle, draw=black, minimum size=60, font=\Huge, line width=1.5}}
\tikzset{selected/.style={->, >=stealth, line width=2}}
\tikzset{redpath/.style={selected, color=red}}
\tikzset{bluepath/.style={selected, color=blue}}
\tikzset{purplepath/.style={selected, color=purple}}
\tikzset{nopath/.style={thick, ->, dashed, line width=2}}
tikzset{EdgeStyle/.style = {
  thick,
  text = black,
  ->,>=stealth'
}}
\node[dummy] (o) at (0,0) {$o$};
\node[task] (v1) at (5,7.5) {$t_1$};
\node[task] (v2) at (5,0) {$t_2$};
\node[task] (v3) at (10,2.5) {$t_3$};
\node[task] (v4) at (15,10) {$t_4$};
\node[task] (v5) at (15,5) {$t_5$};
\node[task] (v6) at (15,0) {$t_6$};
\node[task] (v7) at (20,7.5) {$t_7$};
\node[task] (v8) at (20,2.5) {$t_8$};
\node[dummy] (d) at (25,0) {$d$};
\draw[nopath] (o) edge (v1);
\draw[nopath] (v1) edge (v4);
\draw[nopath] (v4) edge (v7);
\draw[nopath] (v7) edge (d);
\draw[nopath] (o) edge (v3);
\draw[nopath] (v3) edge (v5);
\draw[nopath] (v5) edge (v8);
\draw[nopath] (v8) edge (d);
\draw[nopath] (o) edge (v2);
\draw[nopath, color=red] (v2) edge node[font=\LARGE, color=red, above]{$\theta_{2, 6} = w^\top \xi((2, 6), x)$} (v6);
\draw[nopath] (v6) edge (d);
\draw[nopath] (v1) edge (v3);
\draw[nopath] (v2) edge (v3);
\draw[nopath] (v3) edge (v4);
\draw[nopath] (v3) edge (v6);
\draw[nopath] (v5) edge (v7);
\draw[nopath] (v6) edge (v8);
\node[] (time1) at (-1, -2) {};
\node[] (time2) at (26, -2) {};
\draw[line width=1.5, ->, >=stealth] (time1) edge node[font=\Huge, below, pos=0.95]{time} (time2);
""", options="scale=1")

# ╔═╡ b7477763-33b6-4506-a253-f0700472788d
md"""
## Results: delays propagation
"""

# ╔═╡ cd4f2546-fe46-42db-8197-7278ccd32cbe
begin 
	vspexperience = plot(load("./images/VSP/vsp_experience.png"))
	vspheuristic = plot(load("./images/VSP/vsp_heuristic.png"))
	plot(vspheuristic, vspexperience, layout = (1,2), ticks = nothing, border = nothing, size = (800, 300))
end

# ╔═╡ fa13eb7d-d6f9-48a8-9745-98bdc7e4ede0
md"""
# 2. Theoretical background

A brief introduction to structured learning by imitation
"""

# ╔═╡ 1484d096-0beb-44d7-8192-6948f3ccd7ca
md"""
## Smoothing by regularization

```math
\xrightarrow[\text{instance $x$}]{\text{Problem}}
\fbox{NN $\varphi_w$}
\xrightarrow[\text{direction $\theta$}]{\text{Objective}}
\fbox{MILP $\underset{y \in \mathcal{Y}}{\mathrm{argmax}} ~ \theta^\top y$}
\xrightarrow[\text{solution $\widehat{y}$}]{\text{Candidate}}
\fbox{Loss}
```

The function $\theta \mapsto \underset{y \in \mathcal{Y}}{\mathrm{argmax}} ~ \theta^\top y$ is piecewise constant $\implies$ no gradient information.

Given a convex function $\Omega$, the regularized optimizer is defined by:

```math
\hat{y}_\Omega(\theta) = \underset{y \in \mathrm{conv}(\mathcal{Y})}{\mathrm{argmax}} \{\theta^\top y - \Omega(y)\} 
```
"""

# ╔═╡ 33a8bfd4-c5c6-42a0-add7-334e153f1785
md"""
## Regularization
"""

# ╔═╡ 33523f7c-974e-45d1-968b-63c80bca6cdf
md"""
``n =`` $(@bind n Slider(3:10; default=7, show_value=true))
"""

# ╔═╡ 81011ca8-c063-4ee4-8aaa-1a5021504ad0
begin
	Y = [
		[(0.5 + 0.5*rand()) * cospi(2k/n), (0.5 + 0.5*rand()) * sinpi(2k/n)]
		for k in 0:n-1
	]
	vertex_argmax(θ) = Y[argmax(dot(θ, y) for y in Y)]
end;

# ╔═╡ f908c4ab-3f9c-4f64-89a5-b046d9dba4cc
function plot_polytope(α, predictor; title)
	θ = 0.4 .* [cos(α), sin(α)]
	ŷ = vertex_argmax(θ)
	active_set = get_probability_distribution(predictor, θ)
	A = active_set.atoms
	p = active_set.weights
	ŷΩ = active_set.x
	
	pl = plot(;
		xlim=(-1.1, 1.1),
		ylim=(-1.1, 1.1),
		aspect_ratio=:equal,
		legend=:outerright,
		title=title
	)
	plot!(
		pl,
		vcat(map(first, Y), first(Y[1])),
		vcat(map(last, Y), last(Y[1]));
		fill=(0, :lightgray),
		linestyle=:dash,
		linecolor=:black,
		label=L"\mathrm{conv}(\mathcal{Y})"
	)
	plot!(
		pl,
		[0., θ[1]],
		[0., θ[2]],
		color=:black,
		arrow=true,
		lw=2,
		label=L"\theta"
	)
	scatter!(
		pl,
		[ŷΩ[1]],
		[ŷΩ[2]];
		color=:blue,
		markersize=7,
		label=L"\hat{y}_\Omega(\theta)"
	)
	scatter!(
		pl,
		map(first, A),
		map(last, A);
		markersize=25 .* p .^ 0.5,
		markercolor=:blue,
		markerstrokewidth=0,
		markeralpha=0.4,
		label=nothing
	)
	scatter!(
		pl,
		[ŷ[1]],
		[ŷ[2]];
		color=:red,
		markersize=7,
		markershape=:square,
		label=L"\hat{y}(\theta)"
	)
	pl
end

# ╔═╡ 371a446e-22e3-4607-a6f5-f72d586e4ef6
md"""
``\alpha_{\text{reg}} =`` $(@bind α_reg Slider(0:0.01:2π; default=π))
"""

# ╔═╡ 5cf53359-3e33-4b8e-91ff-4dac4139f315
md"""
	``\varepsilon_{\text{reg}} = `` $(@bind ε_reg Slider(0.01:0.01:1; default=0.01, show_value=true))
	"""

# ╔═╡ 953701fe-c67a-498f-bf83-a50a6b45e38d
begin
	Ω(y) = ε_reg * sum(abs2, y)
	∇Ω(y) = ForwardDiff.gradient(Ω, y)
	regularized = RegularizedGeneric(vertex_argmax, Ω, ∇Ω)
end;

# ╔═╡ 635380fc-59aa-4d62-ab0a-4c8f2e1ec3df
plot_polytope(α_reg, regularized, title="Regularized")

# ╔═╡ da2931b6-4c0b-43cf-882f-328f67f963b2
function path_cost(y; instance)
	θ = true_encoder(instance)
    return return sum(-θ[i] * y[i] for i in eachindex(y))
end;

# ╔═╡ 6a322541-4a04-4201-8117-4079e8e5ca2c
md"""
## Fenchel-Young loss
Natural non-negative & convex loss based on regularization:
```math
\boxed{
\mathcal{L}_{\Omega}^{\text{FY}}(\theta, \bar{y}) = \Omega^*(\theta) + \Omega(\bar{y}) - \theta^\top \bar{y}
}
```
Given a target solution $\bar{y}$ and a parameter $\theta$, a subgradient is given by:
```math
\widehat{y}_{\Omega}(\theta) - \bar{y} \in \partial_\theta \mathcal{L}_{\Omega}^{\text{FY}}(\theta, \bar{y}).
```
The optimization block has meaningful gradients $\implies$ we can backpropagate through the whole pipeline.
"""

# ╔═╡ Cell order:
# ╟─1dbd6f48-d07c-428d-9dad-3bbbf80a73c4
# ╟─0cd10bf9-c31e-4f86-833a-f6f64b951015
# ╟─9de3b7ab-14b0-4a79-bd51-6202f7cdfdfd
# ╟─6cf9db2d-f16d-4e4e-a1e4-915d37a2705f
# ╟─0617b570-c163-4bd6-8a6b-e49653c1af7f
# ╟─8aa02b43-9c28-4d7e-8eac-551b1e8a4e76
# ╟─5e9486a3-5518-44ad-a9f2-d5371092e46f
# ╟─e716f94c-1f4a-4616-bc65-c1e48723bfe3
# ╟─954276ad-e5b9-43c2-a969-30410829e778
# ╟─a8a40434-4b36-411c-b364-a1056b8295a5
# ╟─dc635c3b-3bd5-4542-9970-69acb3bfc207
# ╟─d6c80374-a253-4943-98fb-977c6deefa1d
# ╟─d487df8f-dc41-4f00-be4e-9d5c4b97e7a4
# ╟─ee2daf54-7a9e-4e31-a015-610479671424
# ╟─3f003028-ece9-41e6-98c0-3c03652ef3af
# ╟─25bd7d39-cb39-4bab-879f-54ed98169b34
# ╟─f908c4ab-3f9c-4f64-89a5-b046d9dba4cc
# ╟─eab0af69-82ba-43f1-bc40-7fddfe7b2e12
# ╟─3ff8833b-e8d8-4621-b062-d3065de91ba6
# ╟─c820e809-5d03-4073-8326-1fe782decb44
# ╟─5b6d013f-2d8c-4919-8fe4-4af5219c3634
# ╟─5cb8738a-7c85-4c88-984e-5a86fcd7acd5
# ╟─04e00283-05c2-4b1b-8c44-54fb1dddb124
# ╟─ec6237ae-e7d8-4191-bc2c-8722b7b9fe63
# ╟─ad1a47b9-d9d3-4f39-ad8e-7749c651da12
# ╟─f0ee67da-ff8b-4229-a1fc-3be190a2d0b1
# ╟─4c661db2-312a-4e03-8f66-df2bb68ad9a7
# ╟─52ca4280-f092-4941-aed5-e3fc25b3149a
# ╠═88ba9bb1-02b3-4f32-bf6c-be8f99626f13
# ╟─9dee8b4a-451c-4714-8257-9a47b2133002
# ╟─ea2faddf-38b2-46ab-9a53-2057ade1f198
# ╟─5f023b91-b0ae-4e91-94fb-f56312c8135f
# ╟─c06b600f-3a79-416e-b2d8-3d85c571d2c8
# ╟─155ee558-8b6f-446b-adbe-41355e9745c0
# ╟─0f9a59ac-4a82-4bbd-b662-344491304c53
# ╟─3dfd513a-d8c0-4e04-aa57-02ee1a63367e
# ╟─bf2619d5-8f84-4340-9e6f-8343d687fc03
# ╟─97a8e5d2-85e3-428c-99f0-5348324ea5c6
# ╟─3e268142-8c00-423f-ab45-abb37e904bb2
# ╟─296fc611-5d26-44c4-8df8-209401a8582a
# ╟─7c7a76b5-ff7e-4731-96f4-49100d59e03a
# ╟─c9cef05b-944b-4595-863d-a0312973d5a3
# ╟─b7477763-33b6-4506-a253-f0700472788d
# ╟─cd4f2546-fe46-42db-8197-7278ccd32cbe
# ╟─fa13eb7d-d6f9-48a8-9745-98bdc7e4ede0
# ╟─1484d096-0beb-44d7-8192-6948f3ccd7ca
# ╟─81011ca8-c063-4ee4-8aaa-1a5021504ad0
# ╟─953701fe-c67a-498f-bf83-a50a6b45e38d
# ╟─33a8bfd4-c5c6-42a0-add7-334e153f1785
# ╟─33523f7c-974e-45d1-968b-63c80bca6cdf
# ╟─635380fc-59aa-4d62-ab0a-4c8f2e1ec3df
# ╟─371a446e-22e3-4607-a6f5-f72d586e4ef6
# ╟─5cf53359-3e33-4b8e-91ff-4dac4139f315
# ╟─da2931b6-4c0b-43cf-882f-328f67f963b2
# ╟─6a322541-4a04-4201-8117-4079e8e5ca2c
