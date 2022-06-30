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
    Pkg.add(Pkg.PackageSpec(name="ProgressMeter"))
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
	using ProgressMeter
	using Random
	using SparseArrays
	using Statistics
	using TikzPictures
end;

# ╔═╡ 0617b570-c163-4bd6-8a6b-e49653c1af7f
TableOfContents(depth=1)

# ╔═╡ e716f94c-1f4a-4616-bc65-c1e48723bfe3
begin
	fig = TikzPicture(L"""
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
	""", options="scale=1");
	fig2 = TikzPicture(L"""
	\tikzset{node/.style={fill=red!10, shape=rectangle, draw=black, minimum width=100, minimum height=40, font=\LARGE, line width=1.5}}
	\node[node] (t) at (0, 0) {$t$};
	\node[node] (u) at (7, 0) {$u$};
	\node[] (time1) at (-2, -1) {};
	\node[] (time2) at (9, -1) {};
	\draw[<->, line width=1.5] (t) edge node[below]{slack $\Delta_{u,t}$} (u);
	\draw[->, line width=1.5] (time1) edge node[below, pos=0.95]{time} (time2);
	""", options="scale=1");
end;

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

# ╔═╡ 62ccfefa-9c5e-4b8f-94e0-8d17b54438da
TwoColumn(md"Hello", md"Goodbye", 70, 30)

# ╔═╡ ee2daf54-7a9e-4e31-a015-610479671424
dropfirstdim(z::AbstractArray) = dropdims(z; dims=1);

# ╔═╡ 3f003028-ece9-41e6-98c0-3c03652ef3af
function normalized_hamming_distance(x::AbstractArray{<:Real}, y::AbstractArray{<:Real})
    return mean(x[i] != y[i] for i in eachindex(x))
end;

# ╔═╡ eab0af69-82ba-43f1-bc40-7fddfe7b2e12
md"""
# InferOpt.jl: combinatorial optimization in machine learning pipelines

**[Guillaume Dalle](https://gdalle.github.io/), [Léo Baty](https://batyleo.github.io/), [Louis Bouvier](https://louisbouvier.github.io/) and [Axel Parmentier](https://cermics.enpc.fr/~parmenta/)**

CERMICS, École des Ponts
"""

# ╔═╡ 3ff8833b-e8d8-4621-b062-d3065de91ba6
md"""
> Add photos
"""

# ╔═╡ c820e809-5d03-4073-8326-1fe782decb44
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ 5b6d013f-2d8c-4919-8fe4-4af5219c3634
md"""
# 1. What is it for ?
"""

# ╔═╡ 5cb8738a-7c85-4c88-984e-5a86fcd7acd5
md"""
- Enrich learning pipelines with combinatorial algorithms
- Enhance combinatorial algorithms with learning pipelines
"""

# ╔═╡ afc55865-b3f2-4f39-8c00-2c38957f0289
md"""
## Package overview

InferOpt.jl gathers several state-of-the-art methods at the intersection between Combinatorial Optimization (CO) and Machine Learning (ML).

```math
\xrightarrow[\text{instance}]{\text{Initial}}
\fbox{ML predictor}
\xrightarrow[\text{instance}]{\text{Encoded}}
\fbox{CO algorithm}
\xrightarrow[\text{solution}]{\text{Candidate}}
\text{Loss}
```

**Two learning settings:**
- Learning by imitation
- Learning by experience

**Theoretical challenge:** Differentiating through CO algorithms
"""

# ╔═╡ 04e00283-05c2-4b1b-8c44-54fb1dddb124
md"""
## Many possible applications

- Shortest paths on Warcraft maps $\impliedby$ **today**
- Stochastic Vehicle Scheduling $\impliedby$ **today**
- Two-stage Minimum Spanning Tree
- Single-machine scheduling
- Multi-Agent PathFinding
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

# ╔═╡ e1badec7-4b93-4308-9356-16577e398fe9
md"""
## A glimpse at the dataset (1)
"""

# ╔═╡ fcb144ba-5477-49da-a32c-232545f7511b
begin
	image_label1 = load("./images/image_label1.png")
	plot(image_label1, ticks = nothing, border = nothing)
end

# ╔═╡ c6bf44df-f4a3-4fda-8aa8-d565849acdde
md"""
## A glimpse at the dataset (2)
"""

# ╔═╡ ad1a47b9-d9d3-4f39-ad8e-7749c651da12
begin
	image_label2 = load("./images/image_label2.png")
	plot(image_label2, ticks = nothing, border = nothing)
end

# ╔═╡ f0ee67da-ff8b-4229-a1fc-3be190a2d0b1
md"""
## ML-CO pipeline
"""

# ╔═╡ 4c661db2-312a-4e03-8f66-df2bb68ad9a7
begin
	warcraftpipeline = load("./images/warcraft_pipeline.png")
	plot(warcraftpipeline, ticks = nothing, border = nothing)
end

# ╔═╡ d32c406d-f3d2-450d-a42d-d1ccab1b66b0
md"""
## Training metrics

Small sub-dataset: 80 maps in the train set, 20 in the test set
"""

# ╔═╡ 1a1e818a-d774-417e-bd5c-18f88e116635
begin
	image_lossgap = load("./images/lossgap.png")
	plot(image_lossgap, ticks = nothing, border = nothing)
end

# ╔═╡ 52ca4280-f092-4941-aed5-e3fc25b3149a
md"""
## Test set prediction (1)

We can compare the predicted costs $\theta = \varphi_w(x)$ and the true costs on samples from the test set.
"""

# ╔═╡ 88ba9bb1-02b3-4f32-bf6c-be8f99626f13
begin 
	weights1 = load("./images/weights1.png")
	plot(weights1, ticks = nothing, border = nothing)
end

# ╔═╡ f2df0373-b253-4abf-9719-462512ab029f
md"""
## Test set prediction (2)

We can also compare the predicted shortest path with the theoretical one.
"""

# ╔═╡ ea2faddf-38b2-46ab-9a53-2057ade1f198
begin 
	img_path_label1 = load("./images/image_path_label1.png")
	plot(img_path_label1, ticks = nothing, border = nothing)
end

# ╔═╡ 06c9d007-7fe8-489d-baa9-7264f83cc0d0
md"""
## Test set results (3)

Another example: 
"""

# ╔═╡ 77423e24-7eca-4352-8ee3-0fa7b6e4b687
begin 
	weights2 = load("./images/weights2.png")
	plot(weights2, ticks = nothing, border = nothing)
end

# ╔═╡ 7a6a9c59-df26-4f81-b0b1-77ee99d98810
md"""
## Test set results (4)
"""

# ╔═╡ 916ff5c3-dbec-417b-a6eb-d99c7df7fc8b
begin 
	img_path_label2 = load("./images/image_path_label2.png")
	plot(img_path_label2, ticks = nothing, border = nothing)
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
- **Decision variables**: schedule of vehicle tours
- **Constraint**: all tasks must be fulfilled by exactly one vehicle
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

```math
(H)\left\{
\begin{aligned}
\min_y &\quad c^{veh} \sum_{a\in\delta^+(o)} y_a + \frac{1}{|S|}\sum_{s\in S}\sum_{t\in T} d_t^s \\
\text{s.t.} & \sum_{a\in\delta^-(t)}y_a = \sum_{a\in\delta^+(t)}y_a,\quad & \forall t\in T\\
& \sum_{a\in\delta^+(t)}y_a = 1, & \forall t\in T\\
& d_t^s \geq \varepsilon_t^s, & \forall t\in T,\,\forall s\in S\\
& d_t^s \geq \varepsilon_t^s + \sum_{a=(u, t)\in\delta^-(t)}(d_u^s-\Delta_{u,t}^s)y_a, & \forall t\in T,\,\forall s\in S\\
& y_a\in \{0, 1\}, & \forall a\in A\\
& d_t^s\in \mathbb{R}, & \forall t\in T,\,\forall s\in S
\end{aligned}
\right.
```

``\implies`` does not scale well with number of tasks and scenarios

Other option: use column generation, with a constrained shortest path subproblem

``\implies`` still not enough
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
## Results: loss
"""

# ╔═╡ cd4f2546-fe46-42db-8197-7278ccd32cbe
begin 
	vsp_loss = load("./images/vsp_loss.png")
	plot(vsp_loss, ticks = nothing, border = nothing)
end

# ╔═╡ e87562b4-9b78-46e7-924d-8c966290065a
md"""
## Results: cost gap
"""

# ╔═╡ b0833e2c-9334-499d-be58-50d347f462e4
begin
	vsp_cost = load("./images/vsp_average_cost_gap.png")
	plot(vsp_cost, ticks = nothing, border = nothing)
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
\fbox{Neural network $\varphi_w$}
\xrightarrow[\text{direction $\theta$}]{\text{Objective}}
\fbox{Linear optimizer $\underset{y \in \mathcal{Y}}{\mathrm{argmax}} ~ \theta^\top y$}
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
## Regularized
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
	maximizer(θ) = Y[argmax(dot(θ, y) for y in Y)]
end;

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
	regularized = RegularizedGeneric(maximizer, Ω, ∇Ω)
end;

# ╔═╡ 216003b9-6fe3-49bc-9480-2ee595dc2b86
md"""
## Perturbed
"""

# ╔═╡ 90099c84-cb56-473e-a308-9c1bb4300380
md"""
``\alpha_{\text{pert}} =`` $(@bind α_pert Slider(0:0.01:2π; default=π))
"""

# ╔═╡ a7d44c11-99c7-4ef8-9340-ca55e202b92f
begin
	set_ε_pert = md"""
	``\varepsilon_{\text{pert}} = `` $(@bind ε_pert Slider(0.01:0.01:1; default=0.01, show_value=true))
	"""
	set_nb_samples_pert = md"""
	``M_{\text{pert}} = `` $(@bind nb_samples_pert Slider(2:100; default=10, show_value=true))
	"""
	TwoColumn(set_ε_pert, set_nb_samples_pert, 50, 50)
end

# ╔═╡ a26cbc70-92ce-41a9-b7cd-319ac331efe0
perturbed = PerturbedAdditive(maximizer; ε=ε_pert, nb_samples=nb_samples_pert, seed=0);

# ╔═╡ f908c4ab-3f9c-4f64-89a5-b046d9dba4cc
function plot_polytope(α, predictor; title)
	θ = 0.4 .* [cos(α), sin(α)]
	ŷ = maximizer(θ)
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
		end;

# ╔═╡ 635380fc-59aa-4d62-ab0a-4c8f2e1ec3df
plot_polytope(α_reg, regularized, title="Regularized")

# ╔═╡ 0b4dbe7a-3a75-47b2-b246-ed93459b7e8f
plot_polytope(α_pert, perturbed, title="Perturbed")

# ╔═╡ 60e0f981-8eb6-4d5e-b38a-a973cf40be3a
begin
	one_hot_argmax(θ) = Float64.(1:length(θ) .== argmax(θ));
	soft_argmax(θ; s=1) = exp.(s * θ) ./ sum(exp, s * θ);
	e₁ = [1., 0., 0.]
	e₂ = [0., 1., 0.]
	e₃ = [0., 0., 1.]
	f₁ = e₁ + e₂ + e₃
	f₁ ./= norm(f₁)
	f₂ = e₁ - (e₁'f₁) * f₁
	f₂ ./= norm(f₂)
	f₃ = e₂ - (e₂'f₁) * f₁ - (e₂'f₂) * f₂
	f₃ ./= norm(f₃)
	project2d(x) = [dot(x, f₂), dot(x, f₃)]
	y₁, y₂, y₃ = map(project2d, (e₁, e₂, e₃))
	
	function plot_argmax(α; legend=true)
		θ = 0.35 * (cos(α) * f₂ + sin(α) * f₃)
		ŷ = one_hot_argmax(θ)
		ŷΩ = soft_argmax(θ; s=3.5)
	
		θ_2d = project2d(θ)
		ŷ_2d = project2d(ŷ)
		ŷΩ_2d = project2d(ŷΩ)
	
		λ₁ = dot(ŷΩ, e₁)
		λ₂ = dot(ŷΩ, e₂)
		λ₃ = dot(ŷΩ, e₃)
		
		pl = Plots.plot(; xlim=(-1, 1), ylim=(-1, 1), aspect_ratio=:equal, legend=legend)
		plot!(
			pl,
			[y₁[1], y₂[1], y₃[1], y₁[1]],
			[y₁[2], y₂[2], y₃[2], y₁[2]];
			fill=(0, :lightgray),
			linestyle=:dash,
			linecolor=:black,
			label="simplex Δ³"
		)
		plot!(
			pl,
			[0., θ_2d[1]],
			[0., θ_2d[2]],
			color=:black,
			arrow=true,
			lw=2,
			label="objective θ"
		)
		
		scatter!(
			pl,
			[ŷΩ_2d[1]],
			[ŷΩ_2d[2]];
			color=:blue,
			markersize=5,
			label="regularized argmax"
		)
		scatter!(
			pl,
			[y₁[1], y₂[1], y₃[1]],
			[y₁[2], y₂[2], y₃[2]];
			markersize=20 .* ([λ₁, λ₂, λ₃]).^0.7,
			markercolor=:blue,
			markerstrokewidth=0,
			markeralpha=0.4,
			label=nothing
		)
		scatter!(
			pl,
			[ŷ_2d[1]],
			[ŷ_2d[2]];
			color=:red,
			markersize=5,
			markershape=:square,
			label="hard argmax"
		)
		pl
	end
end;

# ╔═╡ 9f293911-323f-4c91-926b-cff0927c16a1
md"""
## Fenchel-Young loss

Natural non-negative & convex loss based on regularization:

```math
\mathcal{L}_{\Omega}^{\text{FY}}(\theta, \bar{y}) = \Omega^*(\theta) + \Omega(y) - \theta^\top y
```

Given a target solution $\bar{y}$ and a parameter $\theta$, a subgradient is given by:

```math
\widehat{y}_{\Omega}(\theta) - \bar{y} \in \partial_\theta \mathcal{L}_{\Omega}^{\text{FY}}(\theta, \bar{y}).
```


The optimization block has meaningful gradients $\implies$ we can backpropagate in the whole pipeline.
"""

# ╔═╡ 86c31ee6-2b45-46c0-99ef-8e8da7c67717
md"""
# 3. Tutorial
"""

# ╔═╡ 53bd8687-a7bb-43b6-b4b1-f487c9fa40af
md"""
## Problem statement

- We observe the itineraries chosen by a public transport user in different networks
- We want to understand their decision-making process (a.k.a. recover their utility function).

Each dataset point consists in:
- a graph ``G``
- a shortest path ``P`` from the top left to the bottom right corner, taken by the user

We don't know the true costs that were used to compute the shortest path, but we can exploit a set of features to approximate these costs.

We will use `InferOpt` to learn the appropriate weights, so that we may propose relevant paths to the user in the future.
"""

# ╔═╡ 9d28cfad-1ee4-4946-9090-6d06ed985761
md"""
## GridGraphs

- We consider grid graphs, as implemented in [https://github.com/gdalle/GridGraphs.jl](https://github.com/gdalle/GridGraphs.jl).
- Each vertex corresponds to a couple of coordinates ``(i, j)``, where ``1 \leq i \leq h`` and ``1 \leq j \leq w``.
- We only allow the user to move right, down or both $\implies$ ensures acyclicity
- The cost of a move is defined as the cost of the arrival vertex

``\implies`` any grid graph is entirely characterized by its cost matrix ``\theta \in \mathbb{R}^{h \times w}``.
"""

# ╔═╡ b5b1322b-bd82-4f25-b888-7dbefd8fb1e0
h, w = 50, 100;

# ╔═╡ cdffe713-0b1d-45cf-b5d3-ea5b86882986
md"""
## GridGraphs: example
"""

# ╔═╡ 25f0cc4d-f659-44f3-8319-e9a12f8c563a
@bind seed Slider(0:100; default=0)

# ╔═╡ 003ba2de-5aee-4c7d-9af6-2472f714e483
θ = randn(MersenneTwister(seed), h, w);

# ╔═╡ 5ce19f81-2205-4fc2-88dc-ff8e3c50c28e
g = AcyclicGridGraph(θ);

# ╔═╡ 7d2e7333-eded-4168-9364-0b7b63f5acd3
md"""
We can easily compute the shortest path:
"""

# ╔═╡ ef88fae7-1baf-44bc-8405-20acdb9301a0
p = path_to_matrix(g, grid_topological_sort(g, 1, nv(g)));

# ╔═╡ b42d417d-aa67-4988-8c4a-dd105d0353f8
spy(sparse(p))

# ╔═╡ 4633febc-b1ce-43a6-8f3a-854e29c56beb
md"""
## Input data

- We don't know the cost of each vertex.
- We have have access to a set of relevant features.
"""

# ╔═╡ 28437714-35d6-47dd-8609-441fa0a68eda
nb_features, nb_instances = 10, 30;

# ╔═╡ 3614c791-ce6d-41f2-94ae-ed01cf15fbae
md"""
Generate random instances
"""

# ╔═╡ bc03dc04-bcac-4e4a-aeda-9a6b90f495e1
X_train = [randn(nb_features, h, w) for n in 1:nb_instances];

# ╔═╡ a58364b1-debb-4c5d-9f69-6dadb2a57ffa
md"""
Let us assume that the user combines them using a shallow (linear) neural network.
"""

# ╔═╡ 458ab7d6-45dc-43d4-85ed-8ea355aca06d
true_encoder = Chain(Dense(nb_features, 1), dropfirstdim);

# ╔═╡ 67081a13-78fd-485a-89c5-0ca04479a76a
md"""
Compute true (unknown) vertex costs
"""

# ╔═╡ 4435ed2f-718b-444e-8c2b-a7c04cde8ad8
θ_train = [true_encoder(x) for x in X_train];

# ╔═╡ 9f52266e-3ad3-4823-a1ab-dd08294136d6
md"""
The true vertex costs computed from this encoding are then used within longest path computations:

```math
\arg\max_{y\in \{0, 1\}^{h\times w}} \theta^T y
```
"""

# ╔═╡ 04ca9af8-d29b-4694-af98-fce02036023f
function linear_maximizer(θ; instance=nothing)
    g = AcyclicGridGraph(-θ)
    path = grid_topological_sort(g, 1, nv(g))
    return path_to_matrix(g, path)
end;

# ╔═╡ bd4c8210-75ac-45bc-8aa2-4f34dd0fd852
Y_train = [linear_maximizer(θ) for θ in θ_train];

# ╔═╡ 0ca87da2-bb36-4c75-bf59-fe2cfe73edd4
md"""
We create a trainable model with the same structure as the true encoder but another set of randomly-initialized weights.
"""

# ╔═╡ f717b0a9-83a3-400b-8093-80fb6561514f
initial_encoder = Chain(Dense(nb_features, 1), dropfirstdim);

# ╔═╡ bc883d10-c074-4e55-8848-892e7f512556
md"""
## Regularization
"""

# ╔═╡ eaa3491f-3dec-465a-9a8a-96d43cc8c4e8
begin
	set_ε = md"""
	``\varepsilon = `` $(@bind ε Slider(0:0.01:10; default=0.0))
	"""
	set_nb_samples = md"""
	``M = `` $(@bind M Slider(2:50; default=5))
	"""
	TwoColumn(set_ε, set_nb_samples, 50, 50)
end

# ╔═╡ 4107ded4-4e57-4f22-ad50-83735f7a97ff
predictor = PerturbedAdditive(linear_maximizer; ε=ε, nb_samples=M);

# ╔═╡ be133738-eeea-4db2-90d4-47266bf80a65
spy(predictor(θ_train[1]))

# ╔═╡ 4b66eabd-eae6-4ee1-9555-a2baf43c8a2e
md"""
Instead of choosing just one path, it spreads over several possible paths, allowing its output to change smoothly as ``\theta`` varies.
"""

# ╔═╡ 3e384580-500c-4b26-b5ab-d0ec84e1eb40
md"""
## Training

Thanks to this smoothing, we can now train our model with a standard gradient optimizer.
"""

# ╔═╡ d3b46a83-2a9c-49b1-b9be-10e5b8848f9a
regularized_predictor = PerturbedAdditive(linear_maximizer; ε=1.0, nb_samples=5);

# ╔═╡ 5cb477cd-e20c-4006-90b1-8d43a1fa1ce6
fyloss = FenchelYoungLoss(regularized_predictor);

# ╔═╡ f0220f84-07f7-452f-a975-6f08f27a6d0b
md"""
Training loop using Flux:
"""

# ╔═╡ 4cc3ae85-028c-4952-9ad8-94063cee74ae
begin
	encoder = deepcopy(initial_encoder)
	opt = ADAM();
	fylosses = Float64[]
	fyhamming_distances = Float64[]
	for epoch in 1:100
	    l = 0.
	    for (x, y) in zip(X_train, Y_train)
	        grads = gradient(Flux.params(encoder)) do
	            l += fyloss(encoder(x), y)
	        end
	        Flux.update!(opt, Flux.params(encoder), grads)
	    end
		Y_train_pred = [linear_maximizer(encoder(x)) for x in X_train];
		train_error = mean(
		    normalized_hamming_distance(y, y_pred)
				for (y, y_pred) in zip(Y_train, Y_train_pred)
		)
		push!(fyhamming_distances, train_error)
	    push!(fylosses, l)
	end;
end;

# ╔═╡ ba00f149-c675-4dfb-97fb-483df8fa761d
md"""
## Results: Loss

Since the Fenchel-Young loss is convex, the training works well:
"""

# ╔═╡ 28eec921-d948-4ace-b0a0-1a35b6f464d7
plot(fylosses, xlabel="Epoch", ylabel="Loss")

# ╔═╡ 53521e21-7040-493e-802a-cf75cb4c0f65
@info "Final loss" fylosses[end]

# ╔═╡ d5746b74-f170-45ac-ad93-be3e9d32f3a0
md"""
## Results: normalized hamming distance
"""

# ╔═╡ 1cf291f1-7a8a-4573-891d-ab84162e0895
plot(fyhamming_distances, xlabel="Epoch", ylabel="Normalized hamming distance")

# ╔═╡ 5ec3cc3f-3bfb-4bfd-8014-728bf27e140e
@info "Final hamming distance" fyhamming_distances[end]

# ╔═╡ e42a5c8f-5511-46e1-9495-8fc198fae087
md"""
## Training when $\theta$ costs are known

When the user costs $\theta$ are known for our dataset, we can use another loss to leverage this additional information.

``\implies`` Smart "Predict then optimize" setting
"""

# ╔═╡ c1763137-a746-4fc8-b0c7-a4da50105926
spo_loss = SPOPlusLoss(linear_maximizer);

# ╔═╡ 7ad675e8-bbe7-41a8-ad53-decdb8267097
begin
	encoder2 = deepcopy(initial_encoder)
	spolosses = Float64[]
	spohamming_distances = Float64[]
	for epoch in 1:100
	    l = 0.
	    for (x, θ, y) in zip(X_train, θ_train, Y_train)
	        grads = gradient(Flux.params(encoder2)) do
	            l += spo_loss(encoder2(x), θ, y)
	        end
	        Flux.update!(opt, Flux.params(encoder2), grads)
	    end
	    push!(spolosses, l)
		Y_train_pred = [linear_maximizer(encoder2(x)) for x in X_train];
		train_error = mean(
		    normalized_hamming_distance(y, y_pred)
				for (y, y_pred) in zip(Y_train, Y_train_pred)
		)
		push!(spohamming_distances, train_error)
	end;
end;

# ╔═╡ 8010bd8a-5f63-4ee8-8f23-34b59c0297e4
md"""
## Results: Loss
"""

# ╔═╡ 1b17fd8f-008e-4064-a866-332071647796
plot(spolosses, xlabel="Epoch", ylabel="Loss")

# ╔═╡ 910f89b9-64dd-480b-b6d7-19f8eb61923d
@info "Final loss" spolosses[end]

# ╔═╡ c6bac43b-dfab-49f8-ae6c-4d33b8b55663
md"""
## Results: normalized hamming distance
"""

# ╔═╡ 5a6759db-ad6c-48ac-aff3-266b76c9b715
plot(spohamming_distances, xlabel="Epoch", ylabel="Normalized hamming distance")

# ╔═╡ 953523a6-fa73-46ca-a59d-11bd818f8a11
@info "Final hamming distance" spohamming_distances[end] 

# ╔═╡ da2931b6-4c0b-43cf-882f-328f67f963b2
function path_cost(y; instance)
	θ = true_encoder(instance)
    return return sum(-θ[i] * y[i] for i in eachindex(y))
end;

# ╔═╡ ee6a4ba8-1342-448a-999d-aa063e883654
md"""
## Training when optimal paths are unknown

If we cannot have access to chosen paths $y$ or user costs $\theta$ for dataset instances $x$, but have a blackbox cost function that can evaluate a given path, we still can do something !

``\implies`` learning by experience setting
"""

# ╔═╡ 28043665-f5fa-4ebc-8388-9a378ce1e894
path_cost

# ╔═╡ 18dcd447-695f-4c14-b646-5c6b24d961ce
exp_loss = PerturbedComposition(regularized_predictor, path_cost);

# ╔═╡ 53c884aa-3a43-47c5-8695-00f29e68b508
path_cost ∘ regularized_predictor

# ╔═╡ 5eeef94f-5bd3-4165-878b-1b4a66ab71a8
begin
	encoder3 = deepcopy(initial_encoder)
	exp_losses, cost_gaps, exp_hamming_distances = Float64[], Float64[], Float64[]
	optimal_costs = [path_cost(y; instance=x) for (x, y) in zip(X_train, Y_train)]
	for epoch in 1:3000
	    l = 0.
	    for x in X_train
	        grads = gradient(Flux.params(encoder3)) do
	            l += exp_loss(encoder3(x); instance=x)
	        end
	        Flux.update!(opt, Flux.params(encoder3), grads)
	    end
		Y_train_pred = [linear_maximizer(encoder3(x)) for x in X_train];
		train_cost_gap = mean((path_cost(y_pred; instance=x) - c) / abs(c)
				for (x, c, y_pred) in zip(X_train, optimal_costs, Y_train_pred)
		)
		train_error = mean(normalized_hamming_distance(y, y_pred)
				for (y, y_pred) in zip(Y_train, Y_train_pred)
		)
	    push!(exp_losses, l); push!(cost_gaps, train_cost_gap)
		push!(exp_hamming_distances, train_error)
	end
end;

# ╔═╡ 832fa40e-e4ef-42fb-bc25-133d19a5c579
md"""
## Results: loss
"""

# ╔═╡ 2016349b-cfd5-40ef-bfdd-835db6e0f6fe
plot(exp_losses, xlabel="Epoch", ylabel="Loss")

# ╔═╡ 2eb47163-e8dd-4307-8dff-454cabf81d90
@info "Final loss" exp_losses[end]

# ╔═╡ f1425013-66af-44a9-aada-7101251ef0b9
md"""
## Results: normalized hamming distance
"""

# ╔═╡ c45c5d71-933e-4c1b-bf62-a982ed736ed8
plot(exp_hamming_distances, xlabel="Epoch", ylabel="Hamming distances")

# ╔═╡ 5cc13399-73e9-4717-93cc-fe73f11bccc9
@info "Final hamming distance" exp_hamming_distances[end] 

# ╔═╡ f25e58ac-ae39-4c46-9328-5eb5656b37ea
md"""
## Results: cost gap
"""

# ╔═╡ 18657b2f-108e-4f11-ae34-3d889e10e76d
plot(cost_gaps, xlabel="Epoch", ylabel="Cost gap")

# ╔═╡ b042bd90-8b5e-4556-b8a9-542e35cdb6de
@info "Final cost gap" cost_gaps[end] 

# ╔═╡ 5f5733a5-2bb4-4045-8671-f3dc7b0586fb
md"""
# Conclusion
"""

# ╔═╡ d37939ad-4937-46f9-a5f7-5394a8c38ded
md"""
## For more information

- **Main package:** [https://github.com/axelparmentier/InferOpt.jl](https://github.com/axelparmentier/InferOpt.jl)
- paper ?

More advanced examples:
- **Single machine scheduling:** [https://github.com/axelparmentier/SingleMachineScheduling.jl](https://github.com/axelparmentier/SingleMachineScheduling.jl)
- **Two stage spanning tree:** [https://github.com/axelparmentier/TwoStageSpanningTree.jl](https://github.com/axelparmentier/TwoStageSpanningTree.jl)
- **Shortest paths on Warcraft maps:** [https://github.com/LouisBouvier/WarcraftShortestPaths.jl](https://github.com/LouisBouvier/WarcraftShortestPaths.jl)
- **Stochastic vehicle scheduling:** [https://github.com/BatyLeo/StochasticVehicleScheduling.jl](https://github.com/BatyLeo/StochasticVehicleScheduling.jl)
"""

# ╔═╡ fd548869-2e5f-47db-9e29-999b1d323b85
md"""
## Perspectives

> Complete this
"""

# ╔═╡ Cell order:
# ╠═9de3b7ab-14b0-4a79-bd51-6202f7cdfdfd
# ╠═0617b570-c163-4bd6-8a6b-e49653c1af7f
# ╟─e716f94c-1f4a-4616-bc65-c1e48723bfe3
# ╟─a8a40434-4b36-411c-b364-a1056b8295a5
# ╠═d6c80374-a253-4943-98fb-977c6deefa1d
# ╠═62ccfefa-9c5e-4b8f-94e0-8d17b54438da
# ╠═ee2daf54-7a9e-4e31-a015-610479671424
# ╠═3f003028-ece9-41e6-98c0-3c03652ef3af
# ╟─eab0af69-82ba-43f1-bc40-7fddfe7b2e12
# ╟─3ff8833b-e8d8-4621-b062-d3065de91ba6
# ╟─c820e809-5d03-4073-8326-1fe782decb44
# ╟─5b6d013f-2d8c-4919-8fe4-4af5219c3634
# ╟─5cb8738a-7c85-4c88-984e-5a86fcd7acd5
# ╟─afc55865-b3f2-4f39-8c00-2c38957f0289
# ╟─04e00283-05c2-4b1b-8c44-54fb1dddb124
# ╟─ec6237ae-e7d8-4191-bc2c-8722b7b9fe63
# ╟─e1badec7-4b93-4308-9356-16577e398fe9
# ╟─fcb144ba-5477-49da-a32c-232545f7511b
# ╟─c6bf44df-f4a3-4fda-8aa8-d565849acdde
# ╟─ad1a47b9-d9d3-4f39-ad8e-7749c651da12
# ╟─f0ee67da-ff8b-4229-a1fc-3be190a2d0b1
# ╟─4c661db2-312a-4e03-8f66-df2bb68ad9a7
# ╟─d32c406d-f3d2-450d-a42d-d1ccab1b66b0
# ╟─1a1e818a-d774-417e-bd5c-18f88e116635
# ╟─52ca4280-f092-4941-aed5-e3fc25b3149a
# ╟─88ba9bb1-02b3-4f32-bf6c-be8f99626f13
# ╟─f2df0373-b253-4abf-9719-462512ab029f
# ╟─ea2faddf-38b2-46ab-9a53-2057ade1f198
# ╟─06c9d007-7fe8-489d-baa9-7264f83cc0d0
# ╟─77423e24-7eca-4352-8ee3-0fa7b6e4b687
# ╟─7a6a9c59-df26-4f81-b0b1-77ee99d98810
# ╟─916ff5c3-dbec-417b-a6eb-d99c7df7fc8b
# ╟─5f023b91-b0ae-4e91-94fb-f56312c8135f
# ╟─c06b600f-3a79-416e-b2d8-3d85c571d2c8
# ╟─155ee558-8b6f-446b-adbe-41355e9745c0
# ╟─0f9a59ac-4a82-4bbd-b662-344491304c53
# ╟─3dfd513a-d8c0-4e04-aa57-02ee1a63367e
# ╟─bf2619d5-8f84-4340-9e6f-8343d687fc03
# ╟─296fc611-5d26-44c4-8df8-209401a8582a
# ╟─7c7a76b5-ff7e-4731-96f4-49100d59e03a
# ╟─c9cef05b-944b-4595-863d-a0312973d5a3
# ╟─b7477763-33b6-4506-a253-f0700472788d
# ╟─cd4f2546-fe46-42db-8197-7278ccd32cbe
# ╟─e87562b4-9b78-46e7-924d-8c966290065a
# ╟─b0833e2c-9334-499d-be58-50d347f462e4
# ╟─fa13eb7d-d6f9-48a8-9745-98bdc7e4ede0
# ╟─1484d096-0beb-44d7-8192-6948f3ccd7ca
# ╟─81011ca8-c063-4ee4-8aaa-1a5021504ad0
# ╟─953701fe-c67a-498f-bf83-a50a6b45e38d
# ╟─a26cbc70-92ce-41a9-b7cd-319ac331efe0
# ╟─33a8bfd4-c5c6-42a0-add7-334e153f1785
# ╟─33523f7c-974e-45d1-968b-63c80bca6cdf
# ╟─635380fc-59aa-4d62-ab0a-4c8f2e1ec3df
# ╟─371a446e-22e3-4607-a6f5-f72d586e4ef6
# ╟─5cf53359-3e33-4b8e-91ff-4dac4139f315
# ╟─216003b9-6fe3-49bc-9480-2ee595dc2b86
# ╟─0b4dbe7a-3a75-47b2-b246-ed93459b7e8f
# ╟─90099c84-cb56-473e-a308-9c1bb4300380
# ╟─a7d44c11-99c7-4ef8-9340-ca55e202b92f
# ╟─f908c4ab-3f9c-4f64-89a5-b046d9dba4cc
# ╟─60e0f981-8eb6-4d5e-b38a-a973cf40be3a
# ╟─9f293911-323f-4c91-926b-cff0927c16a1
# ╟─86c31ee6-2b45-46c0-99ef-8e8da7c67717
# ╟─53bd8687-a7bb-43b6-b4b1-f487c9fa40af
# ╟─9d28cfad-1ee4-4946-9090-6d06ed985761
# ╠═b5b1322b-bd82-4f25-b888-7dbefd8fb1e0
# ╟─cdffe713-0b1d-45cf-b5d3-ea5b86882986
# ╠═25f0cc4d-f659-44f3-8319-e9a12f8c563a
# ╠═003ba2de-5aee-4c7d-9af6-2472f714e483
# ╠═5ce19f81-2205-4fc2-88dc-ff8e3c50c28e
# ╟─7d2e7333-eded-4168-9364-0b7b63f5acd3
# ╠═ef88fae7-1baf-44bc-8405-20acdb9301a0
# ╠═b42d417d-aa67-4988-8c4a-dd105d0353f8
# ╟─4633febc-b1ce-43a6-8f3a-854e29c56beb
# ╠═28437714-35d6-47dd-8609-441fa0a68eda
# ╟─3614c791-ce6d-41f2-94ae-ed01cf15fbae
# ╠═bc03dc04-bcac-4e4a-aeda-9a6b90f495e1
# ╟─a58364b1-debb-4c5d-9f69-6dadb2a57ffa
# ╠═458ab7d6-45dc-43d4-85ed-8ea355aca06d
# ╟─67081a13-78fd-485a-89c5-0ca04479a76a
# ╠═4435ed2f-718b-444e-8c2b-a7c04cde8ad8
# ╟─9f52266e-3ad3-4823-a1ab-dd08294136d6
# ╠═04ca9af8-d29b-4694-af98-fce02036023f
# ╠═bd4c8210-75ac-45bc-8aa2-4f34dd0fd852
# ╠═0ca87da2-bb36-4c75-bf59-fe2cfe73edd4
# ╠═f717b0a9-83a3-400b-8093-80fb6561514f
# ╟─bc883d10-c074-4e55-8848-892e7f512556
# ╟─eaa3491f-3dec-465a-9a8a-96d43cc8c4e8
# ╠═4107ded4-4e57-4f22-ad50-83735f7a97ff
# ╟─be133738-eeea-4db2-90d4-47266bf80a65
# ╟─4b66eabd-eae6-4ee1-9555-a2baf43c8a2e
# ╟─3e384580-500c-4b26-b5ab-d0ec84e1eb40
# ╠═d3b46a83-2a9c-49b1-b9be-10e5b8848f9a
# ╠═5cb477cd-e20c-4006-90b1-8d43a1fa1ce6
# ╟─f0220f84-07f7-452f-a975-6f08f27a6d0b
# ╠═4cc3ae85-028c-4952-9ad8-94063cee74ae
# ╟─ba00f149-c675-4dfb-97fb-483df8fa761d
# ╠═28eec921-d948-4ace-b0a0-1a35b6f464d7
# ╟─53521e21-7040-493e-802a-cf75cb4c0f65
# ╟─d5746b74-f170-45ac-ad93-be3e9d32f3a0
# ╠═1cf291f1-7a8a-4573-891d-ab84162e0895
# ╟─5ec3cc3f-3bfb-4bfd-8014-728bf27e140e
# ╟─e42a5c8f-5511-46e1-9495-8fc198fae087
# ╠═c1763137-a746-4fc8-b0c7-a4da50105926
# ╠═7ad675e8-bbe7-41a8-ad53-decdb8267097
# ╟─8010bd8a-5f63-4ee8-8f23-34b59c0297e4
# ╠═1b17fd8f-008e-4064-a866-332071647796
# ╟─910f89b9-64dd-480b-b6d7-19f8eb61923d
# ╟─c6bac43b-dfab-49f8-ae6c-4d33b8b55663
# ╟─5a6759db-ad6c-48ac-aff3-266b76c9b715
# ╟─953523a6-fa73-46ca-a59d-11bd818f8a11
# ╟─da2931b6-4c0b-43cf-882f-328f67f963b2
# ╟─ee6a4ba8-1342-448a-999d-aa063e883654
# ╠═28043665-f5fa-4ebc-8388-9a378ce1e894
# ╠═18dcd447-695f-4c14-b646-5c6b24d961ce
# ╠═53c884aa-3a43-47c5-8695-00f29e68b508
# ╠═5eeef94f-5bd3-4165-878b-1b4a66ab71a8
# ╟─832fa40e-e4ef-42fb-bc25-133d19a5c579
# ╠═2016349b-cfd5-40ef-bfdd-835db6e0f6fe
# ╟─2eb47163-e8dd-4307-8dff-454cabf81d90
# ╟─f1425013-66af-44a9-aada-7101251ef0b9
# ╠═c45c5d71-933e-4c1b-bf62-a982ed736ed8
# ╟─5cc13399-73e9-4717-93cc-fe73f11bccc9
# ╟─f25e58ac-ae39-4c46-9328-5eb5656b37ea
# ╠═18657b2f-108e-4f11-ae34-3d889e10e76d
# ╟─b042bd90-8b5e-4556-b8a9-542e35cdb6de
# ╟─5f5733a5-2bb4-4045-8671-f3dc7b0586fb
# ╟─d37939ad-4937-46f9-a5f7-5394a8c38ded
# ╟─fd548869-2e5f-47db-9e29-999b1d323b85
