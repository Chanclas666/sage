"""
Fast functions for the category framework


AUTHOR:

- Simon King (initial version)

"""

#*****************************************************************************
#  Copyright (C) 2014      Simon King <simon.king@uni-jena.de>
#
#  Distributed under the terms of the GNU General Public License (GPL)
#                  http://www.gnu.org/licenses/
#*****************************************************************************
include 'sage/ext/python.pxi'

#######################################
## Sorting

cpdef inline tuple category_sort_key(object category):
    """
    Return ``category._cmp_key``.

    This helper function is used for sorting lists of categories.

    It is semantically equivalent to
    :func:`operator.attrgetter` ``("_cmp_key")``, but currently faster.

    EXAMPLES::

        sage: from sage.categories.category_cy_helper import category_sort_key
        sage: category_sort_key(Rings()) is Rings()._cmp_key
        True
    """
    return category._cmp_key

cpdef tuple _sort_uniq(categories):
    """
    Return the categories after sorting them and removing redundant categories.

    Redundant categories include duplicates and categories which
    are super categories of other categories in the input.

    INPUT:

    - ``categories`` -- a list (or iterable) of categories

    OUTPUT: a sorted tuple of mutually incomparable categories

    EXAMPLES::

        sage: Category._sort_uniq([Rings(), Monoids(), Coalgebras(QQ)])
        (Category of rings, Category of coalgebras over Rational Field)

    Note that, in the above example, ``Monoids()`` does not appear
    in the result because it is a super category of ``Rings()``.
    """
    cdef tuple cats = tuple(sorted(categories, key=category_sort_key, reverse=True))
    cdef list result = []
    cdef bint append
    for category in cats:
        append = True
        for cat in result:
            if cat.is_subcategory(category):
                append = False
                break
        if append:
            result.append(category)
    return tuple(result)

cpdef tuple _flatten_categories(categories, ClasscallMetaclass JoinCategory):
    """
    Return the tuple of categories in ``categories``, while
    flattening join categories.

    INPUT:

    - ``categories`` -- a list (or iterable) of categories

    - ``JoinCategory`` -- A type such that instances of that type will be
      replaced by its super categories. Usually, this type is
      :class:`JoinCategory`.

    .. NOTE::

        It is needed to provide :class:`~sage.categories.category.JoinCategory` as
        an argument, since we need to prevent a circular import.

    EXAMPLES::

        sage: Category._flatten_categories([Algebras(QQ), Category.join([Monoids(), Coalgebras(QQ)]), Sets()], sage.categories.category.JoinCategory)
        (Category of algebras over Rational Field, Category of monoids, Category of coalgebras over Rational Field, Category of sets)
    """
    # Invariant: the super categories of a JoinCategory are not JoinCategories themselves
    cdef list out = []
    for category in categories:
        if isinstance(category, JoinCategory):
            out.extend(category.super_categories())
        else:
            out.append(category)
    return tuple(out)

#############################################
## Join
cdef bint is_supercategory_of_done(new_cat, dict done):
    for cat in done.iterkeys():
        if cat.is_subcategory(new_cat):
            return True
    return False

cpdef tuple join_as_tuple(tuple categories, tuple axioms, tuple ignore_axioms):
    cdef set axiomsS = set(axioms)
    for category in categories:
        axiomsS.update(category.axioms())
    cdef dict done = dict()
    cdef set todo = set()
    cdef frozenset axs
    for category in categories:
        axs = category.axioms()
        for (cat, axiom) in ignore_axioms:
            if category.is_subcategory(cat):
                axs = axs | {axiom}
        done[category] = axs
        for axiom in axiomsS.difference(axs):
            todo.add( (category, axiom) )

    # Invariants:
    # - the current list of categories is stored in the keys of ``done``
    # - todo contains the ``complement`` of done; i.e.
    #   for category in the keys of done,
    #   (category, axiom) is in todo iff axiom is not in done[category]
    cdef list new_cats
    cdef set new_axioms
    while todo:
        (category, axiom) = todo.pop()
        # It's easier to remove categories from done than from todo
        # So we check that ``category`` had not been removed
        if category not in done:
            continue

        # Removes redundant categories
        new_cats = [new_cat for new_cat in <tuple>(category._with_axiom_as_tuple(axiom))
                    if not is_supercategory_of_done(new_cat, done)]
        for cat in done.keys():
            for new_cat in new_cats:
                if new_cat.is_subcategory(cat):
                    del done[cat]
                    break

        new_axioms = set()
        for new_cat in new_cats:
            for axiom in new_cat.axioms():
                if axiom not in axiomsS:
                    new_axioms.add(axiom)

        # Mark old categories with new axioms as todo
        for category in done.iterkeys():
            for axiom in new_axioms:
                todo.add( (category, axiom) )
        for new_cat in new_cats:
            axs = new_cat.axioms()
            for (cat, axiom) in ignore_axioms:
                if new_cat.is_subcategory(cat):
                    axs = axs | {axiom}
            done[new_cat] = axs
            for axiom in axiomsS.difference(axs):
                todo.add( (new_cat, axiom) )

    return _sort_uniq(done.iterkeys())


#############################################
## Axiom related functions

cdef class AxiomContainer(dict):
    def add(self, axiom):
        self[axiom] = len(self)
    def __iadd__(self, L):
        for axiom in L:
            self.add(axiom)
        return self

cpdef get_axiom_index(AxiomContainer all_axioms, str axiom):
    return <object>PyDict_GetItemString(all_axioms, PyString_AsString(axiom))

cpdef tuple canonicalize_axioms(AxiomContainer all_axioms, axioms):
    r"""
    Canonicalize a set of axioms.

    INPUT:

    - ``all_axioms`` -- all available axioms

    - ``axioms`` -- a set (or iterable) of axioms

    .. NOTE::

        :class:`AxiomContainer` provides a fast container for axioms, and the
        collection of axioms is stored in
        :mod:`sage.categories.category_with_axiom`. In order to avoid circular
        imports, we expect that the collection of all axioms is provided as an
        argument to this auxiliary function.

    OUTPUT:

    A set of axioms as a tuple sorted according to the order of the
    tuple ``all_axioms`` in :mod:`sage.categories.category_with_axiom`.

    EXAMPLES::

        sage: from sage.categories.category_with_axiom import canonicalize_axioms, all_axioms
        sage: canonicalize_axioms(all_axioms, ["Commutative", "Connected", "WithBasis", "Finite"])
        ('Finite', 'Connected', 'WithBasis', 'Commutative')
        sage: canonicalize_axioms(all_axioms, ["Commutative", "Connected", "Commutative", "WithBasis", "Finite"])
        ('Finite', 'Connected', 'WithBasis', 'Commutative')
    """
    cdef list L = list(set(axioms))
    L.sort(key = (all_axioms).__getitem__)
    return tuple(L)
