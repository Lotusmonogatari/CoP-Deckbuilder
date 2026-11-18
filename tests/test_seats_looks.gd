extends GutTest
## Broadcast and Woodblock draw the semicircle too (2026-11-18): the geometry stays inside the half-ring.


func test_a_rim_point_sits_on_the_faceted_edge() -> void:
	var centre := Vector2(500, 500)
	for a in [PI, PI + 0.3, PI * 1.5, TAU - 0.2, TAU]:
		var p := SeatsMeter._rim_point(centre, 200.0, a, SeatsMeter.BROADCAST_FACETS)
		var d := p.distance_to(centre)
		assert_true(d <= 200.01 and d >= 200.0 * cos(PI / float(SeatsMeter.BROADCAST_FACETS) * 0.5) - 0.01, "angle %s is on its chord" % a)
		assert_true(p.y <= centre.y + 0.01, "in the upper half")


func test_a_band_piece_is_a_closed_shape_inside_the_ring() -> void:
	var centre := Vector2(500, 500)
	for facets in [SeatsMeter.BROADCAST_FACETS, SeatsMeter.SMOOTH_FACETS]:
		var pts := SeatsMeter._band(centre, 160.0, 200.0, PI + 0.4, PI + 1.9, facets, 0.1 if facets == SeatsMeter.BROADCAST_FACETS else 0.0)
		assert_gte(pts.size(), 6)
		for p: Vector2 in pts:
			assert_true(p.distance_to(centre) >= 160.0 * 0.97 and p.distance_to(centre) <= 200.01, "inside the ring")
