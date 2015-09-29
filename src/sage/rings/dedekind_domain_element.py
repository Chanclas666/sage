"""
Base class for Dedekind domain elements
"""

#*****************************************************************************
#       Copyright (C) 2005 William Stein <wstein@gmail.com>
#
#  Distributed under the terms of the GNU General Public License (GPL)
#
#    This code is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    General Public License for more details.
#
#  The full text of the GPL is available at:
#
#                  http://www.gnu.org/licenses/
#*****************************************************************************

from sage.misc.superseded import deprecation
deprecation(19167, "the module sage.rings.dedekind_domain_element is deprecated, import from sage.structure.element instead")

from sage.structure.element import DedekindDomainElement

def is_DedekindDomainElement(x):
    """
    Check to see if ``x`` is a :class:`DedekindDomainElement`.

    EXAMPLES::

        sage: import sage.rings.dedekind_domain_element
        doctest:...: DeprecationWarning: the module sage.rings.dedekind_domain_element is deprecated, import from sage.structure.element instead
        See http://trac.sagemath.org/19167 for details.
        sage: sage.rings.dedekind_domain_element.is_DedekindDomainElement(DedekindDomainElement(QQ))
        True
    """
    return isinstance(x, DedekindDomainElement)
